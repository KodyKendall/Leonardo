#!/usr/bin/env bash
#
# test/bin_update_sync.sh — regression test for bin/update's platform-allowlist sync.
#
# Builds a throwaway upstream repo + a fork pointing at it, runs `bin/update --sync-only`, and
# asserts the v1 allowlist behavior: platform paths (bin, migrations) are pulled wholesale while
# the client's own work, bin/local/, customized non-allowlisted files, .gitignore entries, and
# instance.json are all preserved — and unrelated staged work is never swept into the sync commit.
#
# Also covers run_pending_migrations retry behavior (scenarios 3-4): a mock docker binary is
# injected into PATH so tests never need a live container.
#
# Pure git + bash; no docker, no network. Exits non-zero on any failed assertion.
# Run: bash test/bin_update_sync.sh
#
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPDATE="$REPO_ROOT/bin/update"
[ -f "$UPDATE" ] || { echo "FATAL: $UPDATE not found"; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok()  { echo "  PASS  $1"; }
no()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
chk() { if eval "$1"; then ok "$2"; else no "$2"; fi; }

# Keep retry loops fast in all scenarios (production defaults: 12 retries, 5s sleep).
export MIGRATE_MAX_RETRIES=2
export MIGRATE_RETRY_SLEEP_SEC=0

# ---------- UPSTREAM (on main) ----------
up="$WORK/upstream"
mkdir -p "$up" && cd "$up"
git init -q -b main && git config user.email u@u && git config user.name up
mkdir -p rails/db/migrate bin rails/app/javascript/llamapress
echo "A" > rails/db/migrate/20260101_a.rb
echo "D-new-upstream" > rails/db/migrate/20260105_d.rb
printf 'services:\n  llamabot:\n    image: kody06/llamabot:9.9.9-UPSTREAM\n' > docker-compose.yml
cp "$UPDATE" bin/update && chmod +x bin/update
echo "UPSTREAM-helper" > bin/helper.sh
echo "UPSTREAM-JS" > rails/app/javascript/llamapress/element_selector.js
printf '.env\n.leonardo/instance.json\n.leonardo/update.log\nUPSTREAM_ONLY_IGNORE\n' > .gitignore
git add -A && git commit -qm "upstream base"

# ---------- CLIENT (fork) ----------
cd "$WORK" && git clone -q upstream client && cd client
git remote rename origin upstream
git config user.email c@c && git config user.name client
echo "C-client-own" > rails/db/migrate/20260601_client_c.rb       # app's own migration
mkdir -p bin/local && echo "azure" > bin/local/azure.sh           # bespoke client script
echo "CLIENT_ONLY_IGNORE" >> .gitignore                           # client gitignore entry
echo "CLIENT-COMPOSE" > docker-compose.yml                        # NOT on v1 allowlist -> must survive
echo "CLIENT-JS" > rails/app/javascript/llamapress/element_selector.js  # NOT on v1 allowlist -> must survive
mkdir -p .leonardo && echo '{"name":"bc-dev-2"}' > .leonardo/instance.json
mkdir -p rails/app/views/home && echo "client app" > rails/app/views/home/index.html.erb
git add -A && git add -f .leonardo/instance.json && git commit -qm "client state"

echo "== scenario 1: clean sync =="
bash bin/update --sync-only >/dev/null 2>&1
chk '[ -f rails/db/migrate/20260601_client_c.rb ]'            "client migration kept"
chk 'grep -q D-new-upstream rails/db/migrate/20260105_d.rb'   "upstream migration pulled"
chk '[ -f bin/helper.sh ]'                                    "upstream bin/ file pulled"
chk '[ -f bin/local/azure.sh ]'                               "bin/local preserved"
chk 'grep -q CLIENT-COMPOSE docker-compose.yml'               "non-allowlisted docker-compose untouched (v1)"
chk 'grep -q CLIENT-JS rails/app/javascript/llamapress/element_selector.js' "non-allowlisted JS untouched (v1)"
chk 'grep -qx CLIENT_ONLY_IGNORE .gitignore'                  "gitignore client line kept"
chk 'grep -qx UPSTREAM_ONLY_IGNORE .gitignore'                "gitignore upstream line added"
chk '! git ls-files --error-unmatch .leonardo/instance.json >/dev/null 2>&1' "instance.json untracked"
chk '[ -f .leonardo/instance.json ]'                          "instance.json kept on disk"
chk 'grep -q "client app" rails/app/views/home/index.html.erb' "Leo app work untouched"
chk 'git log -1 --pretty=%s | grep -q platform-sync'          "scoped platform-sync commit created"
chk '[ -z "$(git status --porcelain)" ]'                      "working tree clean after sync"

echo "== scenario 2: unrelated staged work blocks the commit =="
head_before="$(git rev-parse HEAD)"
echo "UPSTREAM-helper v2" > "$up/bin/helper.sh"; (cd "$up" && git commit -qam "bump")
echo "LEO EDIT" > rails/app/views/home/index.html.erb
git add rails/app/views/home/index.html.erb
bash bin/update --sync-only >/dev/null 2>&1
chk '[ "$(git rev-parse HEAD)" = "$head_before" ]'            "no commit made while unrelated work staged"
chk 'git diff --cached --name-only | grep -q home/index'      "Leo staged work left intact"

# ---- scenarios 3 & 4: run_pending_migrations retry / loud-failure -----
# A minimal git repo (no upstream remote → sync skips gracefully) combined with
# a mock docker binary lets us exercise the retry loop without a live stack.
mig_dir="$WORK/mig_test"
mkdir -p "$mig_dir/bin" "$mig_dir/.leonardo"
cd "$mig_dir"
git init -q -b main && git config user.email t@t && git config user.name test
git commit -q --allow-empty -m "init"
cp "$UPDATE" bin/update && chmod +x bin/update

mock_bin="$WORK/mock_bin"
mkdir -p "$mock_bin"

echo "== scenario 3: transient exec-ready miss — db:migrate runs after retry =="
s3="$WORK/state3"
mkdir -p "$s3"
echo "1" > "$s3/fail_until"   # exec true fails on attempt 1, succeeds on attempt 2

cat > "$mock_bin/docker" <<DOCKEREOF
#!/usr/bin/env bash
s3="${s3}"
case "\$*" in
  "compose version") exit 0 ;;
  "compose exec -T llamapress true")
    cnt=\$(cat "\$s3/cnt" 2>/dev/null || echo 0)
    cnt=\$((cnt+1)); echo \$cnt > "\$s3/cnt"
    fail_until=\$(cat "\$s3/fail_until" 2>/dev/null || echo 0)
    [ "\$cnt" -le "\$fail_until" ] && exit 1; exit 0 ;;
  "compose exec -T llamapress bin/rails db:migrate")
    echo ok >> "\$s3/migrate_calls"; exit 0 ;;
  *) exit 1 ;;
esac
DOCKEREOF
chmod +x "$mock_bin/docker"

PATH="$mock_bin:$PATH" bash "$mig_dir/bin/update" --sync-only >/dev/null 2>&1
chk 'grep -q ok "$s3/migrate_calls" 2>/dev/null' \
  "db:migrate called after transient exec-ready failure"
cnt3=$(cat "$s3/cnt" 2>/dev/null || echo 0)
chk '[ "$cnt3" -gt 1 ]' "exec-ready check retried before calling migrate"

echo "== scenario 4: permanently unavailable — loud error, non-zero exit =="
s4="$WORK/state4"
mkdir -p "$s4"

cat > "$mock_bin/docker" <<DOCKEREOF
#!/usr/bin/env bash
s4="${s4}"
case "\$*" in
  "compose version") exit 0 ;;
  "compose exec -T llamapress true")
    cnt=\$(cat "\$s4/cnt" 2>/dev/null || echo 0)
    cnt=\$((cnt+1)); echo \$cnt > "\$s4/cnt"
    exit 1 ;;
  *) exit 1 ;;
esac
DOCKEREOF
chmod +x "$mock_bin/docker"

PATH="$mock_bin:$PATH" bash "$mig_dir/bin/update" --sync-only \
  2>"$s4/stderr" >/dev/null
s4_rc=$?
chk '[ "$s4_rc" -ne 0 ]' "non-zero exit when llamapress never becomes exec-ready"
chk 'grep -q ERROR "$s4/stderr" 2>/dev/null' "ERROR logged on migration timeout"

echo
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; else echo "$fails FAILED"; fi
exit "$fails"
