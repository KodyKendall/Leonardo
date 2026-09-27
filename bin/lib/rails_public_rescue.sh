#!/usr/bin/env bash
#
# rails_public_rescue.sh — sourced by bin/update. Expects PROJECT_DIR, COMPOSE_FILE and
# log() from the caller. See test/rails_public_rescue.sh.
#
# Until 0.7.11 only rails/public/uploads was bind-mounted, so icons and manifests Leo
# wrote into /rails/public lived in the container layer and every recreate threw them
# away (leo-reare's app icon went back to a red square five times in six weeks). Once
# the compose mounts the whole directory, the host copy is what gets served, so the
# files Leo wrote must be on the host BEFORE that first recreate.
#
# Only files the container CHANGED or ADDED (`docker diff`) are copied, and they win
# over the host copy: that is what the customer actually sees. Unchanged stock files are
# left to the image entrypoint's no-clobber seed — copying the old stock icon here would
# pin the red square on the host for good.

# $1 = the running llamapress container id. Never fails the update.
rescue_rails_public() {
  local cid="$1" line path rel dst n=0
  [ -n "$cid" ] || return 0
  grep -qE '^[[:space:]]*-[[:space:]]*\./rails/public:/rails/public(:|[[:space:]]|$)' \
    "$PROJECT_DIR/$COMPOSE_FILE" 2>/dev/null || return 0
  if docker inspect -f '{{range .Mounts}}{{println .Destination}}{{end}}' "$cid" 2>/dev/null \
      | grep -qx '/rails/public'; then
    return 0
  fi

  while IFS= read -r line; do
    case "$line" in [AC]\ /rails/public/*) ;; *) continue ;; esac
    path="${line#? }"
    rel="${path#/rails/public/}"
    case "$rel" in uploads|uploads/*) continue ;; esac
    docker exec "$cid" test -f "$path" 2>/dev/null || continue
    dst="$PROJECT_DIR/rails/public/$rel"
    mkdir -p "$(dirname "$dst")" 2>/dev/null || true
    if docker cp "$cid:$path" "$dst" 2>/dev/null; then
      n=$((n + 1))
    else
      log "rescue: WARN could not copy $path out of the llamapress container"
    fi
  done < <(docker diff "$cid" 2>/dev/null)

  log "rescue: copied $n file(s) Leo wrote into the llamapress container's /rails/public to the host"
  return 0
}
