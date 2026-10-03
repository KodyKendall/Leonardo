#!/usr/bin/env bash
#
# bin/lib/update_recreate.sh — the DETACHED half of bin/update: recreate the containers,
# then write the final marker. bin/update schedules this (systemd-run, nohup fallback)
# under `flock .leonardo/update.lock` and exits; it must not write "success" itself,
# because at that point nothing has been recreated yet (leo-sepe, 2026-09-27: the marker
# said success while llamabot was gone for 31 minutes).
#
# Usage: DC="docker compose" LLAMABOT_TARGET=x LLAMAPRESS_TARGET=y \
#          bash bin/lib/update_recreate.sh <project_dir> [service...]
# No services = recreate everything (`up -d`). Exit 0 only when the recreate succeeded;
# bin/update chains `docker image prune -af` on that.
set -uo pipefail

PROJECT_DIR="$1"; shift
cd "$PROJECT_DIR" || exit 1
SERVICES=("$@")
DC="${DC:-docker compose}"
MARKER=".leonardo/last_update.json"
LOG=".leonardo/update.log"
PROJECT="${COMPOSE_PROJECT_NAME:-$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]//g')}"

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" >> "$LOG"; }

# Same shape as bin/update's write_marker (the UI reads this file).
write_marker() { # $1 status  $2 message
  cat > "$MARKER" <<JSON
{
  "status": "$1",
  "message": "$2",
  "llamabot_target": "${LLAMABOT_TARGET:-}",
  "llamapress_target": "${LLAMAPRESS_TARGET:-}",
  "changed_services": "${SERVICES[*]:-}",
  "finished_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON
}

# A recreate that dies mid-way leaves compose's temporary `<12-hex-id>_<project>-<svc>-N`
# container behind, and every later `up -d` fails on the name conflict until it is gone.
remove_rename_leftovers() {
  docker ps -a --format '{{.Names}}' 2>/dev/null \
    | grep -E "^[0-9a-f]{12}_${PROJECT}-" \
    | while read -r name; do
        log "removing leftover container from an interrupted recreate: $name"
        docker rm -f "$name" >> "$LOG" 2>&1
      done
}

log "recreate start (${SERVICES[*]:-all services})"
if $DC up -d "${SERVICES[@]}" >> "$LOG" 2>&1; then
  ok=1
else
  log "up -d failed; clearing leftovers and retrying once"
  remove_rename_leftovers
  if $DC up -d "${SERVICES[@]}" >> "$LOG" 2>&1; then ok=1; else ok=0; fi
fi

if [ "$ok" -eq 1 ]; then
  log "recreate ok"
  write_marker "success" "updated ${SERVICES[*]:-all services}; containers recreated"
  exit 0
fi
log "FAILED: recreate failed"
write_marker "failed" "recreate failed: see .leonardo/update.log"
exit 1
