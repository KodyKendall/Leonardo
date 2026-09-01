#!/usr/bin/env bash
#
# backup_status.sh — how to read an `aws s3 sync` exit code.
#
# Sourced by the backup scripts; contains no side effects so it can be unit tested
# (see test/backup_exit_codes.sh).
#
# AWS CLI v2 exit codes for `s3 sync`:
#   0  every file transferred
#   2  the command completed, but one or more files were SKIPPED — typically because
#      they were unreadable or vanished mid-run. This is a WARNING.
#   1  a real failure (auth, network, bad bucket).
#
# quick_backup.sh used to wrap the sync in a bare `if`, which treats 2 as failure, and
# then gated both database dumps on that result. One unreadable file anywhere under the
# project directory therefore cost both databases, 66 consecutive times, while the run
# still wrote its "last backup" pointer (agent_task 160).
#
# Worth knowing before "just add an --exclude": `aws s3 sync` performs its readability
# check BEFORE applying exclude filters, so an exclude does not suppress the warning and
# does not change the exit code. Measured twice on a live box.

# True when the sync did its job, whether or not it skipped anything.
aws_sync_ok() {
    case "${1:-}" in
        0|2) return 0 ;;
        *)   return 1 ;;
    esac
}

# True only for the "completed with skipped files" case, so the summary can say so.
aws_sync_warned() {
    [ "${1:-}" = "2" ]
}
