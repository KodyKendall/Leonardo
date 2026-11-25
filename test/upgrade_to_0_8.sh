#!/usr/bin/env bash
#
# test/upgrade_to_0_8.sh — LP-52 C: bin/upgrade-to-0.8 upgrades a box, rolls itself back on any
# failure, refuses protected / needs-human boxes without changing anything, and is safe to re-run.
#
# A fake Leonardo checkout (real git) with a stub bin/update, a mock docker (containers, scan,
# codemods, Rails) and a mock curl (the public edge + sign-in). No network, no real docker.
# Run: bash test/upgrade_to_0_8.sh
#
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPGRADE="$REPO_ROOT/bin/upgrade-to-0.8"
[ -f "$UPGRADE" ] || { echo "FATAL: $UPGRADE not found"; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok()  { echo "  PASS  $1"; }
no()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
chk() { if eval "$1"; then ok "$2"; else no "$2"; fi; }

export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1   # no host identity: exercise the fallback
export UPGRADE_POLL_SEC=0 UPGRADE_UPDATE_TIMEOUT_SEC=5 UPGRADE_BOOT_TIMEOUT_SEC=3
mock_bin="$WORK/mock_bin"; mkdir -p "$mock_bin"

# ---- mock docker --------------------------------------------------------------------------------
# Knobs (files in $ST): rails_bad_on_<tag> (Rails 500 on that llamapress tag), fail_db:migrate,
# fail_zeitwerk:check. Containers report the tags in $ST/tag_<svc>.
cat > "$mock_bin/docker" <<'EOF'
#!/usr/bin/env bash
ST="$MOCK_STATE"
printf '%s\n' "$*" >> "$ST/docker_calls"
case "$*" in
  "compose version") exit 0 ;;
  "compose ps -q llamabot") echo cid_llamabot; exit 0 ;;
  "compose ps -q llamapress") echo cid_llamapress; exit 0 ;;
  "inspect --format {{.Config.Image}} cid_llamabot") echo "kody06/llamabot:$(cat "$ST/tag_llamabot")"; exit 0 ;;
  "inspect --format {{.Config.Image}} cid_llamapress") echo "kody06/llamapress-simple:$(cat "$ST/tag_llamapress")"; exit 0 ;;
  "image inspect"*) exit 0 ;;
esac
if [ "$1" = "run" ]; then
  overlay=""; for a in "$@"; do case "$a" in */rails:/overlay*) overlay="${a%%:/overlay*}" ;; esac; done
  # The codemod run is `--entrypoint ruby ... apply /overlay`; the scan run (entrypoint bash)
  # also says "apply", but only on its scratch copy inside the container.
  if printf '%s ' "$@" | grep -q -- "--entrypoint ruby .* apply /overlay"; then   # codemods
    grep -rl "enum status:" "$overlay" | while read -r f; do sed -i 's/enum status: /enum :status, /' "$f"; done
    echo '{"auto":[],"human":[]}'; exit 0
  fi
  if grep -rq "Rails.application.secrets" "$overlay"; then b=needs_human
  elif grep -rq "enum status:" "$overlay"; then b=auto_only
  else b=0_fixes; fi
  echo "{\"box\":\"x\",\"bucket\":\"$b\",\"auto\":[],\"human\":[],\"zeitwerk\":\"ok\"}"; exit 0
fi
if [ "$1" = "compose" ] && [ "$2" = "exec" ]; then
  args="$*"
  case "$args" in
    *"curl"*"localhost:3000"*)
      [ -f "$ST/rails_bad_on_$(cat "$ST/tag_llamapress")" ] && { echo -n 500; exit 0; }
      echo -n 200; exit 0 ;;
    *"db:migrate"*) [ -f "$ST/fail_db:migrate" ] && exit 1; exit 0 ;;
    *"zeitwerk:check"*) [ -f "$ST/fail_zeitwerk:check" ] && exit 1; exit 0 ;;
    *"insert!"*) cat > "$ST/smoke_pw"; echo "$args" | grep -o 'SMOKE_EMAIL=[^ ]*' >> "$ST/smoke_created"; exit 0 ;;
    *"delete_all"*) echo "$args" | grep -o 'SMOKE_EMAIL=[^ ]*' >> "$ST/smoke_deleted"; exit 0 ;;
  esac
fi
exit 0
EOF

# ---- mock curl: the public edge ---------------------------------------------------------------
# Knobs: edge_down_on_<tag> (edge 502 on that llamapress tag), smoke_fail (password rejected).
cat > "$mock_bin/curl" <<'EOF'
#!/usr/bin/env bash
ST="$MOCK_STATE"
printf '%s\n' "$*" >> "$ST/curl_calls"
out=""; fmt=""; post=0; prev=""
for a in "$@"; do
  [ "$prev" = "-o" ] && out="$a"
  [ "$prev" = "-w" ] && fmt="$a"
  [ "$a" = "--data-urlencode" ] && post=1
  prev="$a"
done
tag="$(cat "$ST/tag_llamapress")"
if [ -f "$ST/edge_down_on_$tag" ]; then
  [ "$fmt" = "%{http_code} %{size_download}" ] && echo -n "502 0" || echo -n 502; exit 0
fi
if [ "$fmt" = "%{http_code} %{size_download}" ]; then echo -n "200 4321"; exit 0; fi
if [ "$post" = 1 ]; then
  pw="$(cat)"
  if [ ! -f "$ST/smoke_fail" ] && [ "$pw" = "$(cat "$ST/smoke_pw" 2>/dev/null)" ]; then
    touch "$ST/signed_in"; echo -n 303
  else echo -n 422; fi
  exit 0
fi
if [ -f "$ST/signed_in" ]; then echo -n 302; exit 0; fi
[ -n "$out" ] && echo '<input type="hidden" name="authenticity_token" value="tok123" />' > "$out"
echo -n 200
EOF
chmod +x "$mock_bin/docker" "$mock_bin/curl"

# ---- fake box -----------------------------------------------------------------------------------
new_box() { # $1 name  $2 kind: clean|enum|secrets
  local P="$WORK/box_$1"
  rm -rf "$P"; mkdir -p "$P/bin/lib" "$P/rails/app/models" "$P/.leonardo"
  cp "$UPGRADE" "$P/bin/"; cp "$REPO_ROOT/bin/lib/rails8_common.sh" "$REPO_ROOT/bin/lib/rails8_scan.rb" "$P/bin/lib/"
  cat > "$P/bin/update" <<'EOF'
#!/usr/bin/env bash
ST="$MOCK_STATE"
echo "$1 $2" >> "$ST/update_calls"
if [ -f "$ST/update_fail_to_$2" ]; then
  echo '{"status": "failed"}' > .leonardo/last_update.json; exit 1
fi
echo "$1" > "$ST/tag_llamabot"; echo "$2" > "$ST/tag_llamapress"
echo '{"status": "success"}' > .leonardo/last_update.json
EOF
  echo "{\"instance_name\": \"$1\"}" > "$P/.leonardo/instance.json"
  printf '.leonardo/instance.json\n.leonardo/last_update.json\n' > "$P/.gitignore"
  case "$2" in
    enum) printf 'class Order < ApplicationRecord\n  enum status: { a: 0 }\nend\n' > "$P/rails/app/models/order.rb" ;;
    secrets) printf 'K = Rails.application.secrets.k\n' > "$P/rails/app/models/k.rb" ;;
    *) printf 'class Order < ApplicationRecord\nend\n' > "$P/rails/app/models/order.rb" ;;
  esac
  printf 'leo-protected\n' > "$P/.leonardo/never_touch.txt"
  printf '# institutional\nleo-ro\n' > "$P/.leonardo/read_only.txt"
  git -C "$P" init -q && git -C "$P" add -A && git -C "$P" -c user.name=t -c user.email=t@t commit -qm init
  export MOCK_STATE="$WORK/state_$1"; rm -rf "$MOCK_STATE"; mkdir -p "$MOCK_STATE"
  echo 0.7.21 > "$MOCK_STATE/tag_llamabot"; echo 0.7.20 > "$MOCK_STATE/tag_llamapress"
  BOXDIR="$P"
}
run() { # extra args...
  (cd "$BOXDIR" && PATH="$mock_bin:$PATH" bash bin/upgrade-to-0.8 "$@") > "$MOCK_STATE/out" 2>&1 </dev/null
}
ST() { echo "$MOCK_STATE"; }
commits() { git -C "$BOXDIR" log --format=%s; }
marker() { sed -nE "s/.*\"$1\": \"([^\"]*)\".*/\1/p" "$BOXDIR/.leonardo/upgrade_0_8.json" 2>/dev/null; }
OKARGS=(--snapshot-id snap-123 --edge-url https://rails-x.leo.llamapress.ai)

echo "== refuses protected / needs-human boxes, changing nothing"
for case in "leo-protected:clean:NEVER-TOUCH" "leo-ro:clean:read-only" "leo-secret:secrets:needs_human"; do
  IFS=: read -r name kind why <<< "$case"
  new_box "$name" "$kind"; head0="$(git -C "$BOXDIR" rev-parse HEAD)"
  run "${OKARGS[@]}"; rc=$?
  chk '[ $rc -eq 10 ]' "$why box: exits 10"
  chk 'grep -q "$why" "$MOCK_STATE/out"' "$why box: says why"
  chk '[ "$(git -C "$BOXDIR" rev-parse HEAD)" = "$head0" ] && [ -z "$(git -C "$BOXDIR" status --porcelain)" ]' "$why box: no commit, tree untouched"
  chk '[ ! -f "$MOCK_STATE/update_calls" ] && [ ! -e "$BOXDIR/.leonardo/upgrade_0_8.json" ]' "$why box: no bin/update, no marker"
done
new_box leo-a clean
run --edge-url https://x; chk '[ $? -eq 10 ] && grep -q "snapshot" "$MOCK_STATE/out"' "no snapshot id -> refused"
run --snapshot-id s; chk '[ $? -eq 10 ] && grep -q "edge-url" "$MOCK_STATE/out"' "no edge URL -> refused"
rm "$BOXDIR/.leonardo/never_touch.txt"
run "${OKARGS[@]}"; chk '[ $? -eq 10 ] && grep -q "NEVER-TOUCH list not found" "$MOCK_STATE/out"' "missing protected list -> refused (fail closed)"

echo "== success with codemods"
new_box leo-enum enum
echo "local edit" > "$BOXDIR/rails/app/models/wip.rb"     # uncommitted overlay work
run "${OKARGS[@]}"; rc=$?
chk '[ $rc -eq 0 ]' "exits 0"
chk '[ "$(marker status)" = "upgraded" ]' "marker: upgraded"
chk '[ "$(marker snapshot_id)" = "snap-123" ]' "marker: snapshot id recorded"
chk '[ "$(marker previous_llamabot)" = "0.7.21" ] && [ "$(marker previous_llamapress)" = "0.7.20" ]' "marker: previous 0.7.x tags recorded"
chk '[ "$(commits | sed -n 1,2p | tr "\n" "|")" = "Rails 8 codemods|Before Rails 8 upgrade|" ]' "state commit, then ONE codemods commit"
chk 'git -C "$BOXDIR" show --stat HEAD | grep -q "rails/app/models/order.rb" && [ "$(git -C "$BOXDIR" show --stat --format= HEAD | grep -c "|")" = "1" ]' "codemods commit holds only the codemod change"
chk 'grep -q "enum :status, " "$BOXDIR/rails/app/models/order.rb"' "codemod applied"
chk '[ "$(cat "$MOCK_STATE/update_calls")" = "0.8.0 0.8.0" ]' "bin/update 0.8.0 0.8.0, once"
chk '[ "$(cat "$MOCK_STATE/tag_llamapress")" = "0.8.0" ]' "box runs 0.8.0"
chk '[ -f "$MOCK_STATE/signed_in" ]' "sign-in smoke signed in through the edge"
chk 'diff <(sed "s/SMOKE_EMAIL=//" "$MOCK_STATE/smoke_created") <(sed "s/SMOKE_EMAIL=//" "$MOCK_STATE/smoke_deleted") >/dev/null' "smoke user deleted afterwards"
pw="$(cat "$MOCK_STATE/smoke_pw")"
chk '[ ${#pw} -ge 20 ] && ! grep -rqF "$pw" "$BOXDIR/.leonardo" "$MOCK_STATE/docker_calls" "$MOCK_STATE/curl_calls" "$MOCK_STATE/out"' "smoke password never in log, marker, argv or output"
chk '! git -C "$BOXDIR" log --name-only --format= | grep -q "^.leonardo/upgrade_0_8"' "upgrade log/marker never committed"

echo "== success with 0 fixes: no codemods commit"
new_box leo-clean clean
run "${OKARGS[@]}"; rc=$?
chk '[ $rc -eq 0 ] && [ "$(marker status)" = "upgraded" ]' "upgraded"
chk '! commits | grep -q "Rails 8 codemods"' "no codemods commit"
chk '[ "$(marker codemod_commit)" = "" ]' "marker: no codemod commit"

echo "== running twice is a no-op"
calls_before="$(wc -l < "$MOCK_STATE/docker_calls")"; head1="$(git -C "$BOXDIR" rev-parse HEAD)"; m1="$(cat "$BOXDIR/.leonardo/upgrade_0_8.json")"
run "${OKARGS[@]}"; rc=$?
chk '[ $rc -eq 0 ] && grep -q "already upgraded" "$MOCK_STATE/out"' "exits 0 with 'already upgraded'"
chk '[ "$(git -C "$BOXDIR" rev-parse HEAD)" = "$head1" ]' "no new commit"
chk '[ "$(wc -l < "$MOCK_STATE/update_calls")" = "1" ]' "no second bin/update (no recreate)"
chk '[ "$m1" = "$(cat "$BOXDIR/.leonardo/upgrade_0_8.json")" ]' "marker untouched (no new snapshot recorded)"
chk '! sed -n "$((calls_before + 1)),\$p" "$MOCK_STATE/docker_calls" | grep -q "^run "' "no scan/codemod container started"

echo "== boot fails on 0.8.0 -> rolls back"
new_box leo-boot enum
touch "$MOCK_STATE/rails_bad_on_0.8.0"
run "${OKARGS[@]}"; rc=$?
chk '[ $rc -eq 1 ]' "exits 1"
chk '[ "$(marker status)" = "rolled_back" ] && [ "$(marker failed_step)" = "boot" ]' "marker: rolled_back, failed_step=boot"
chk '[ -n "$(marker log_excerpt)" ]' "marker: carries a log excerpt"
chk '[ "$(tail -1 "$MOCK_STATE/update_calls")" = "0.7.21 0.7.20" ]' "bin/update back to the exact previous tags"
chk '[ "$(cat "$MOCK_STATE/tag_llamapress")" = "0.7.20" ]' "box back on 0.7.20"
chk 'commits | sed -n 1p | grep -q "^Revert \"Rails 8 codemods\""' "codemod commit reverted"
chk 'grep -q "enum status: " "$BOXDIR/rails/app/models/order.rb"' "overlay code back to the original"
chk 'tail -3 "$MOCK_STATE/curl_calls" | grep -q "users/sign_in"' "edge re-checked after rollback"

echo "== re-run after the rollback starts clean, codemods applied once"
rm "$MOCK_STATE/rails_bad_on_0.8.0"
run "${OKARGS[@]}"; rc=$?
chk '[ $rc -eq 0 ] && [ "$(marker status)" = "upgraded" ]' "second attempt upgrades"
chk '[ "$(commits | grep -c "^Rails 8 codemods$")" = "2" ] && [ "$(commits | sed -n 1p)" = "Rails 8 codemods" ]' "one new codemods commit for the new attempt"
chk '[ "$(grep -c "enum :status, " "$BOXDIR/rails/app/models/order.rb")" = "1" ] && ! grep -q "enum :status, :status" "$BOXDIR/rails/app/models/order.rb"' "codemod not applied twice"

echo "== sign-in smoke fails -> rolls back"
new_box leo-smoke clean
touch "$MOCK_STATE/smoke_fail"
run "${OKARGS[@]}"; rc=$?
chk '[ $rc -eq 1 ] && [ "$(marker status)" = "rolled_back" ] && [ "$(marker failed_step)" = "sign_in" ]' "rolled_back, failed_step=sign_in"
chk '[ "$(wc -l < "$MOCK_STATE/smoke_deleted")" -ge 1 ]' "smoke user deleted even on failure"

echo "== rollback itself fails -> rollback_failed"
new_box leo-dead clean
touch "$MOCK_STATE/rails_bad_on_0.8.0" "$MOCK_STATE/update_fail_to_0.7.20"
run "${OKARGS[@]}"; rc=$?
chk '[ $rc -eq 2 ]' "exits 2"
chk '[ "$(marker status)" = "rollback_failed" ]' "marker: rollback_failed (page-worthy)"
chk 'grep -q "snap-123" "$BOXDIR/.leonardo/upgrade_0_8.json"' "marker names the snapshot to restore"

echo "== report hook runs on every status change"
new_box leo-hook clean
UPGRADE_REPORT_CMD="grep -o '\"status\": \"[a-z_]*\"' >> $WORK/hook.log <" run "${OKARGS[@]}"
chk 'grep -q upgraded "$WORK/hook.log" && grep -q updating "$WORK/hook.log" && grep -q snapshot "$WORK/hook.log"' "hook saw snapshot, updating, upgraded"

echo
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; exit 0; fi
echo "$fails FAILED"; exit 1
