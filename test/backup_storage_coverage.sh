#!/usr/bin/env bash
#
# test/backup_storage_coverage.sh — regression tests for the two SI#327 backup defects.
#
#  Defect 1: the backup captured a hardcoded volume list and could not know it was wrong.
#            Seven boxes stored uploads outside every backed-up volume; the nightly job
#            reported success while protecting nothing.
#  Defect 2: `hybrid` restore takes volumes at FULL_TS and a NEWER database at QUICK_TS,
#            manufacturing orphaned blobs for every file uploaded in between.
#
# Pure bash. No S3, no docker, no live app. Run: bash test/backup_storage_coverage.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$REPO_ROOT/bin/backups/cloud/lib/storage_coverage.sh"
[ -f "$LIB" ] || { echo "FATAL: $LIB not found"; exit 2; }
# shellcheck source=/dev/null
. "$LIB"

fails=0
ok()  { echo "  PASS  $1"; }
no()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
chk() { if eval "$1"; then ok "$2"; else no "$2"; fi; }
eq()  { if [ "$1" = "$2" ]; then ok "$3"; else no "$3 (got '$1', want '$2')"; fi; }

# Container paths the volume backup actually captures.
BACKED_UP="/rails/storage /var/lib/postgresql/data"

echo "== Defect 1: storage coverage is derived, not assumed =="

root_is_covered "/rails/storage" $BACKED_UP
eq "$?" "0" "the correct root is reported as covered"

# This is the exact shape of the seven-box incident.
root_is_covered "/rails/tmp/storage" $BACKED_UP
eq "$?" "1" "an uploads root under tmp/ is reported NOT covered"

root_is_covered "" $BACKED_UP
eq "$?" "2" "an S3-backed box (no local root) is skipped, not failed"

# A prefix that merely starts with a covered path must not count as covered.
root_is_covered "/rails/storage_old" $BACKED_UP
eq "$?" "1" "a sibling path is not mistaken for a covered one"

echo
echo "== Defect 2: a restore never hands back a DB newer than the files =="

eq "$(restore_mode '' '')"                            "none"            "no pointers at all -> none"
eq "$(restore_mode '20260821-010000' '')"             "full"            "full only -> full"
eq "$(restore_mode '' '20260821-010000')"             "quick"           "quick only -> quick"
eq "$(restore_mode '20260821-020000' '20260821-010000')" "full"         "full newer than quick -> full"
eq "$(restore_mode '20260821-010000' '20260821-020000')" "hybrid-refused" \
   "quick newer than full is REFUSED by default (orphan-generating)"
eq "$(restore_mode '20260821-010000' '20260821-020000' yes)" "hybrid"   "explicit opt-in still allows hybrid"

eq "$(timestamp_gap_human '20260816-013000' '20260821-144500')" "5d 13h 15m" \
   "the skipped window is reported in human terms (rsb-dev's real gap)"
eq "$(timestamp_gap_human '20260821-010000' '20260821-014100')" "0d 0h 41m" \
   "a small gap is still reported"

echo
echo "== Wiring: the scripts must actually use the helpers =="
chk 'grep -q "storage_coverage.sh" "$REPO_ROOT/bin/backups/cloud/2_backup_docker_volumes_to_s3.sh"' \
    "backup script sources the coverage helper"
chk 'grep -q "storage_coverage.sh" "$REPO_ROOT/bin/backups/cloud/master_restore_all.sh"' \
    "master restore sources the coverage helper"
chk 'grep -q "restore_mode" "$REPO_ROOT/bin/backups/cloud/master_restore_all.sh"' \
    "master restore decides its mode through restore_mode()"

echo
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; else echo "$fails FAILED"; fi
exit "$fails"
