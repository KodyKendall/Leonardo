#!/usr/bin/env bash
# storage_coverage.sh — shared, side-effect-free helpers for the backup/restore scripts.
#
# Mothership SI#327: the backup captured a hardcoded volume list and had no way to know
# it was wrong. Seven customer boxes wrote uploads to Rails.root.join("tmp/storage") —
# not one of the four volumes — so the nightly backup ran, SUCCEEDED, and reported green
# while protecting nothing. "A backup that cannot see what it is missing is not a backup."
#
# Sourced by 2_backup_docker_volumes_to_s3.sh, 9_restore_docker_volumes_from_s3.sh and
# master_restore_all.sh. Kept as pure functions so test/backup_storage_coverage.sh can
# exercise the decisions with no S3, no docker and no live app.

# Ask the APPLICATION where it actually stores files, rather than trusting a constant.
# Empty output means "no local root" — an S3-backed box (crm-2/crm-4 legitimately run
# svc=amazon). Those are skipped, never failed.
# $1 = compose service name (default: llamapress)
resolve_storage_root() {
  local svc="${1:-llamapress}"
  docker compose exec -T "$svc" sh -c \
    'bundle exec rails runner "print ActiveStorage::Blob.service.try(:root).to_s" 2>/dev/null' \
    2>/dev/null | tr -d '\r' | tail -n 1
}

# Is the resolved root inside a directory the volume backup actually captures?
# $1 = storage root, $2... = container mount paths that ARE backed up.
# Returns 0 (covered), 1 (NOT covered), or 2 (nothing to judge — no local root).
root_is_covered() {
  local root="$1"; shift
  [ -z "$root" ] && return 2          # S3-backed box: not our problem, not a failure
  local m
  for m in "$@"; do
    case "$root/" in "$m/"*) return 0 ;; esac
  done
  return 1
}

# Decide the restore mode from the two S3 pointer timestamps.
#
# `hybrid` restores volumes at FULL_TS and then overlays a NEWER database from QUICK_TS,
# which manufactures orphaned blobs by construction: every file uploaded between the two
# timestamps gets its row back and its file left behind. Measured on 145 boxes: 15 were
# hybrid, with gaps from 41 minutes to 5 days 13 hours. So hybrid is now REFUSED unless
# the caller explicitly opts in ($3 = "yes"), and it always reports the gap.
#
# $1 = FULL_TS, $2 = QUICK_TS, $3 = allow_hybrid ("yes" to opt in)
# Echoes: none | full | quick | hybrid | hybrid-refused
restore_mode() {
  local full="$1" quick="$2" allow="${3:-no}"
  if   [ -z "$full" ] && [ -z "$quick" ]; then echo "none"
  elif [ -n "$full" ] && [ -z "$quick" ]; then echo "full"
  elif [ -z "$full" ] && [ -n "$quick" ]; then echo "quick"
  elif [[ "$quick" > "$full" ]]; then
    if [ "$allow" = "yes" ]; then echo "hybrid"; else echo "hybrid-refused"; fi
  else echo "full"
  fi
}

# Human-readable gap between two YYYYMMDD-HHMMSS (or YYYYMMDD_HHMMSS) stamps, so the
# operator sees how much file history a hybrid restore would skip.
# $1 = FULL_TS, $2 = QUICK_TS
timestamp_gap_human() {
  local a b sa sb d
  a="$(echo "$1" | tr -d '_-')"; b="$(echo "$2" | tr -d '_-')"
  sa=$(date -u -d "${a:0:8} ${a:8:2}:${a:10:2}:${a:12:2}" +%s 2>/dev/null) || { echo "unknown"; return; }
  sb=$(date -u -d "${b:0:8} ${b:8:2}:${b:10:2}:${b:12:2}" +%s 2>/dev/null) || { echo "unknown"; return; }
  d=$(( sb - sa )); [ "$d" -lt 0 ] && d=$(( -d ))
  printf '%dd %dh %dm' $(( d / 86400 )) $(( (d % 86400) / 3600 )) $(( (d % 3600) / 60 ))
}
