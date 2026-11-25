#!/usr/bin/env bash
#
# test/rails8_fleet_scan.sh — LP-52 B: bin/rails8-fleet-scan writes one CSV row per box, prints
# the bucket counts, skips NEVER-TOUCH / read-only boxes without connecting to them, records an
# unreachable box instead of dropping it, and changes nothing on any box.
#
# "Remote" is a local exec wrapper and docker is a mock that returns a canned scan per box, so
# this needs no ssh, no docker and no Ruby. Run: bash test/rails8_fleet_scan.sh
#
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLEET="$REPO_ROOT/bin/rails8-fleet-scan"
[ -f "$FLEET" ] || { echo "FATAL: $FLEET not found"; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok()  { echo "  PASS  $1"; }
no()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
chk() { if eval "$1"; then ok "$2"; else no "$2"; fi; }

mock_bin="$WORK/mock_bin"; mkdir -p "$mock_bin"
export MOCK_STATE="$WORK/state"; mkdir -p "$MOCK_STATE"

# docker: the per-box scan's `docker run` prints a canned report row for the box named by --box.
cat > "$mock_bin/docker" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$MOCK_STATE/docker_calls"
case "$1" in
  compose) exit 0 ;;
  image) exit 0 ;;
  run)
    box=""; tier=""; prev=""
    for a in "$@"; do
      [ "$prev" = "--box" ] && box="$a"
      [ "$prev" = "--tier" ] && tier="$a"
      prev="$a"
    done
    case "$box" in
      leo-clean) echo "leo-clean,n1,$tier,llamabot=0.7.21 llamapress=0.7.20,0_fixes,\"\",\"\",ok" ;;
      leo-enum)  echo "leo-enum,n1,$tier,llamabot=0.7.21 llamapress=0.7.20,auto_only,app/models/a.rb:2 enum_keyword_form,\"\",ok" ;;
      leo-hard)  echo "leo-hard,n2,$tier,llamabot=0.7.21 llamapress=0.7.20,needs_human,\"\",config/x.rb:1 application_secrets,ok" ;;
    esac
    exit 0 ;;
esac
exit 0
EOF
chmod +x "$mock_bin/docker"

# "Remote exec" that behaves like ssh: joins its trailing args and runs them through a shell,
# locally. A box named leo-down is unreachable. Records every box connected to.
cat > "$WORK/fake_remote" <<'EOF'
#!/usr/bin/env bash
box="$1"; shift
echo "$box" >> "$MOCK_STATE/connected"
[ "$box" = "leo-down" ] && { echo "ssh: connect to host: Connection timed out" >&2; exit 255; }
exec bash -c "$*"
EOF
chmod +x "$WORK/fake_remote"

# Fake boxes: each has a Leonardo dir with a rails/ overlay and an instance.json.
for b in leo-clean leo-enum leo-hard leo-never leo-readonly leo-down; do
  mkdir -p "$WORK/boxes/$b/rails/app/models" "$WORK/boxes/$b/.leonardo"
  echo "{\"instance_name\": \"$b\"}" > "$WORK/boxes/$b/.leonardo/instance.json"
  echo "class A; end" > "$WORK/boxes/$b/rails/app/models/a.rb"
done
cat > "$WORK/inventory.csv" <<EOF
box,node,owner_tier,ssh_target,project_dir
leo-clean,n1,internal,x,$WORK/boxes/leo-clean
leo-enum,n1,free,x,$WORK/boxes/leo-enum
leo-hard,n2,paid,x,$WORK/boxes/leo-hard
leo-never,n2,paid,x,$WORK/boxes/leo-never
leo-readonly,n3,free,x,$WORK/boxes/leo-readonly
leo-down,n3,free,x,$WORK/boxes/leo-down
EOF
printf '# owner sign-off only\nleo-never\n' > "$WORK/never_touch.txt"
printf 'leo-readonly   # institutional\n' > "$WORK/read_only.txt"

snap() { (cd "$WORK/boxes" && find . -type f -exec sha1sum {} + | sort); }
before="$(snap)"
# The remote side unpacks the scanner with mktemp -d; give it its own TMPDIR so the cleanup
# check is not fooled by anything else writing to /tmp on a shared box.
mkdir -p "$WORK/remote_tmp"

echo "== fleet scan"
out="$(TMPDIR="$WORK/remote_tmp" PATH="$mock_bin:$PATH" bash "$FLEET" --inventory "$WORK/inventory.csv" \
  --never-touch "$WORK/never_touch.txt" --read-only "$WORK/read_only.txt" \
  --exec "$WORK/fake_remote {box}" --out "$WORK/scan.csv" 2>"$WORK/err")"; rc=$?
echo "$out" | sed 's/^/    /'
chk '[ $rc -eq 0 ]' "exits 0"
chk '[ -f "$WORK/scan.csv" ]' "writes the CSV"
chk 'head -1 "$WORK/scan.csv" | grep -qx "box,node,owner_tier,image_tags,bucket,auto_fixes,human_fixes,zeitwerk"' "CSV header has the spec columns"
chk '[ "$(tail -n +2 "$WORK/scan.csv" | wc -l)" -eq 6 ]' "one row per box (6)"
row() { grep "^$1," "$WORK/scan.csv"; }
chk 'row leo-clean | grep -q ",0_fixes,"' "clean box -> 0_fixes"
chk 'row leo-enum | grep -q ",auto_only,"' "enum box -> auto_only"
chk 'row leo-hard | grep -q ",needs_human,"' "secrets box -> needs_human"
chk 'row leo-never | grep -q "^leo-never,n2,paid,,skipped,"' "NEVER-TOUCH box -> skipped"
chk 'row leo-readonly | grep -q "^leo-readonly,n3,free,,skipped,"' "read-only box -> skipped"
chk 'row leo-down | grep -q ",scan_failed,"' "unreachable box -> scan_failed, not dropped"
chk 'row leo-enum | grep -q "^leo-enum,n1,free,"' "node and owner tier come from the inventory"
chk 'echo "$out" | grep -q "0 fixes: 1"' "count: 0 fixes"
chk 'echo "$out" | grep -q "auto-fixes only: 1"' "count: auto-fixes only"
chk 'echo "$out" | grep -q "needs a human: 1"' "count: needs a human"
chk 'echo "$out" | grep -q "skipped: 2"' "count: skipped"
chk 'echo "$out" | grep -q "scan failed: 1"' "count: scan failed"
chk '! grep -qx "leo-never\|leo-readonly" "$MOCK_STATE/connected"' "protected boxes are never connected to"
chk '[ "$before" = "$(snap)" ]' "no file on any box changed"
chk '[ -z "$(ls -A "$WORK/remote_tmp")" ] && [ "$(grep -c . "$MOCK_STATE/connected")" -ge 4 ]' "temp copy of the scanner removed afterwards"
chk 'grep -q -- "--network none" "$MOCK_STATE/docker_calls"' "scan container has no network"
chk '! grep "^run" "$MOCK_STATE/docker_calls" | grep -E -- "-v [^ ]*/boxes/[^ ]*:[^ ]*( |$)" | grep -vq ":ro"' "every box mount is read-only"
# The old enum form crashes Rails 8 at load, so zeitwerk:check must run on the CODEMODDED copy;
# otherwise every auto-fixable box is misclassed needs_human (found in the 2026-11-18 real run).
apply_at="$(grep -n "rails8_scan.rb apply /tmp/ov" "$MOCK_STATE/docker_calls" | sed -n 1p | cut -d: -f1)"
zw_at="$(grep -n "zeitwerk:check" "$MOCK_STATE/docker_calls" | sed -n 1p | cut -d: -f1)"
chk '[ -n "$apply_at" ] && [ -n "$zw_at" ] && [ "$apply_at" -lt "$zw_at" ]' "codemods applied to a scratch copy before zeitwerk:check"

echo "== refuses an unsafe box name"
printf 'box,node,owner_tier,ssh_target,project_dir\nleo;rm -rf /,n1,free,x,%s\n' "$WORK/boxes/leo-clean" > "$WORK/bad.csv"
PATH="$mock_bin:$PATH" bash "$FLEET" --inventory "$WORK/bad.csv" --never-touch "$WORK/never_touch.txt" \
  --read-only "$WORK/read_only.txt" --exec "$WORK/fake_remote {box}" --out "$WORK/bad_out.csv" >/dev/null 2>&1
chk 'grep -q ",scan_failed,.*unsafe" "$WORK/bad_out.csv"' "box name with shell characters is not run"

echo "== protected lists are required"
PATH="$mock_bin:$PATH" bash "$FLEET" --inventory "$WORK/inventory.csv" --never-touch "$WORK/nope.txt" \
  --read-only "$WORK/read_only.txt" --exec "$WORK/fake_remote {box}" --out "$WORK/x.csv" >/dev/null 2>&1; rc=$?
chk '[ $rc -ne 0 ] && [ ! -f "$WORK/x.csv" ]' "missing never_touch list -> refuses to scan anything"

echo
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; exit 0; fi
echo "$fails FAILED"; exit 1
