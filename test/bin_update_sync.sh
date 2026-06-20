#!/usr/bin/env bash
#
# test/bin_update_sync.sh — regression test for bin/update's platform-allowlist sync.
#
# Builds a throwaway upstream repo + a fork pointing at it, runs `bin/update --sync-only`, and
# asserts the v1 allowlist behavior: platform paths (bin, migrations) are pulled wholesale while
# the client's own work, bin/local/, customized non-allowlisted files, .gitignore entries, and
# instance.json are all preserved — and unrelated staged work is never swept into the sync commit.
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

echo
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; else echo "$fails FAILED"; fi
exit "$fails"
