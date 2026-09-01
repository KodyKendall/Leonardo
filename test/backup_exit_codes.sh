#!/usr/bin/env bash
#
# test/backup_exit_codes.sh — regression tests for the quick-backup exit-code defect
# (mothership agent_task 160, found on leo-palevi-dev and reproduced on teton, 2026-08-30).
#
# The defect: `aws s3 sync` in AWS CLI v2 returns exit code 2 for "completed, but some
# files were skipped". That is a WARNING. quick_backup.sh wrapped the sync in a bare `if`,
# so exit 2 set OVERALL_OK=false, and both database dumps were gated on that flag.
#
# Result: ONE unreadable file anywhere under the project directory cost both databases.
# It ran that way 66 consecutive times and still wrote last-quick-backup.txt, so the
# mothership's backup_exists? reported a backup that never happened. The customer
# noticed before we did.
#
# Note for anyone tempted by the obvious fix: an --exclude does NOT work. `aws s3 sync`
# performs its readability check BEFORE applying exclude filters, so the warning and the
# exit 2 both survive. Only decoupling the stages and accepting exit 2 fixes this class.
#
# Pure bash. No S3, no docker, no live app: the aws and docker CLIs are stubbed on PATH.
# Run: bash test/backup_exit_codes.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/bin/backups/cloud/quick_backup.sh"
LIB="$REPO_ROOT/bin/backups/cloud/lib/backup_status.sh"

[ -f "$SCRIPT" ] || { echo "FATAL: $SCRIPT not found"; exit 2; }
[ -f "$LIB" ]    || { echo "FATAL: $LIB not found (extract the exit-code helpers)"; exit 2; }
# shellcheck source=/dev/null
. "$LIB"

fails=0
ok()  { echo "  PASS  $1"; }
no()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
eq()  { if [ "$1" = "$2" ]; then ok "$3"; else no "$3 (got '$1', want '$2')"; fi; }
has() { if printf '%s' "$1" | grep -q -- "$2"; then ok "$3"; else no "$3"; fi; }
hasnt() { if printf '%s' "$1" | grep -q -- "$2"; then no "$3"; else ok "$3"; fi; }

echo "== The exit-code rule itself =="

aws_sync_ok 0; eq "$?" "0" "exit 0 (everything copied) is success"
aws_sync_ok 2; eq "$?" "0" "exit 2 (completed, files skipped) is success — THE BUG"
aws_sync_ok 1; eq "$?" "1" "exit 1 (real failure) is a failure"
aws_sync_ok 255; eq "$?" "1" "an unknown exit code is treated as a failure"

if aws_sync_warned 2; then ok "exit 2 is reported as a warning"; else no "exit 2 is reported as a warning"; fi
if aws_sync_warned 0; then no "exit 0 is not a warning"; else ok "exit 0 is not a warning"; fi

# ---------------------------------------------------------------------------
# End-to-end control flow, with the AWS and docker CLIs stubbed.
# ---------------------------------------------------------------------------

# $1 = exit code the stubbed `aws s3 sync` returns
# $2 = exit code the stubbed `pg_dump` returns
#
# Sets RUN_OUT, RUN_RC and RUN_CALLS. Deliberately NOT called inside $( ), which would
# run it in a subshell and drop every one of those.
RUN_OUT=""
RUN_RC=0
RUN_CALLS=""

run_backup() {
  local sync_rc="$1" dump_rc="$2"
  local tmp; tmp="$(mktemp -d)"
  mkdir -p "$tmp/bin" "$tmp/project"

  # This is the shape of the incident: a file the backup user cannot read.
  mkdir -p "$tmp/project/.leonardo/reprodir"
  echo secret > "$tmp/project/.leonardo/reprodir/unreadable.txt"
  chmod 000 "$tmp/project/.leonardo/reprodir/unreadable.txt" 2>/dev/null || true

  cat > "$tmp/bin/aws" <<EOF
#!/usr/bin/env bash
# Record every invocation so the test can assert which stages actually ran.
echo "aws \$*" >> "$tmp/calls.log"
case "\$1 \$2" in
  "sts get-caller-identity") echo "123456789012 backup-user"; exit 0 ;;
  "s3 sync")
      # The real CLI prints this to stderr and still exits 2.
      echo "warning: Skipping file .leonardo/reprodir/unreadable.txt. File/Directory is not readable." >&2
      exit $sync_rc ;;
  "s3 cp") cat > /dev/null; exit 0 ;;
esac
exit 0
EOF

  cat > "$tmp/bin/docker" <<EOF
#!/usr/bin/env bash
echo "docker \$*" >> "$tmp/calls.log"
# \`docker compose exec -T db pg_dump -U postgres <database> ...\`
for a in "\$@"; do case "\$a" in *_production) echo "-- dump of \$a";; esac; done
exit $dump_rc
EOF

  chmod +x "$tmp/bin/aws" "$tmp/bin/docker"

  PATH="$tmp/bin:$PATH" bash "$SCRIPT" test-instance "s3://bucket/test" "$tmp/project" \
      > "$tmp/out.log" 2>&1
  RUN_RC=$?
  RUN_OUT="$(cat "$tmp/out.log" 2>/dev/null)"
  RUN_CALLS="$(cat "$tmp/calls.log" 2>/dev/null)"

  chmod 644 "$tmp/project/.leonardo/reprodir/unreadable.txt" 2>/dev/null || true
  rm -rf "$tmp"
}

echo
echo "== An unreadable source file must not cost the databases (the incident) =="

run_backup 2 0
has "$RUN_CALLS" "llamapress_production" "step 2 dumps llamapress_production despite the skipped file"
has "$RUN_CALLS" "llamabot_production"   "step 3 dumps llamabot_production despite the skipped file"
eq  "$RUN_RC" "0" "the run exits 0 — a skipped file is a warning, not a failure"
has "$RUN_CALLS" "last-quick-backup" "the backup pointer IS written when the databases were dumped"

echo
echo "== A partial result is reported honestly, not collapsed =="

has "$RUN_OUT" "warning" "the summary calls the source step a warning"
hasnt "$RUN_OUT" "Backup FAILED" "a warning-only run is not reported as FAILED"

echo
echo "== A REAL source failure still must not cost the databases =="

run_backup 1 0
has "$RUN_CALLS" "llamapress_production" "the databases are dumped on their own merit"
has "$RUN_CALLS" "llamabot_production"   "both databases are dumped on their own merit"
eq  "$RUN_RC" "1" "a real source failure still fails the run overall"

echo
echo "== The pointer must not lie =="

run_backup 0 1
hasnt "$RUN_CALLS" "last-quick-backup" "no pointer is written when a database dump failed"
eq "$RUN_RC" "1" "a failed database dump fails the run"

echo
if [ "$fails" -eq 0 ]; then
  echo "All backup exit-code tests passed."
  exit 0
fi
echo "$fails test(s) FAILED."
exit 1
