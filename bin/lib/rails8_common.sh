# bin/lib/rails8_common.sh — shared by bin/rails8-scan and bin/upgrade-to-0.8 (LP-52).
# Sourced, not run. Expects PROJECT_DIR (the Leonardo dir on the box) to be set.

R8_IMAGE_DEFAULT="kody06/llamapress-simple:0.8.0"
R8_SCANNER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rails8_scan.rb"

r8_dc() { if docker compose version >/dev/null 2>&1; then echo "docker compose"; else echo "docker-compose"; fi; }

# The box name the mothership knows it by: DNS_NAME, else instance.json's instance_name.
r8_box_name() {
  if [ -n "${DNS_NAME:-}" ]; then echo "$DNS_NAME"; return; fi
  sed -nE 's/.*"instance_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' \
    "$PROJECT_DIR/.leonardo/instance.json" 2>/dev/null | head -n1
}

# The tag a service's RUNNING container uses (what the box actually serves), e.g. 0.7.20.
r8_current_tag() { # $1 service
  local cid img
  cid="$(cd "$PROJECT_DIR" && $(r8_dc) ps -q "$1" 2>/dev/null | head -n1)"
  [ -n "$cid" ] || return 1
  img="$(docker inspect --format '{{.Config.Image}}' "$cid" 2>/dev/null)" || return 1
  [ -n "$img" ] || return 1
  echo "${img##*:}"
}

# Is $1 listed in file $2? One box name per line; blank lines and # comments ignored.
r8_listed() { # $1 box  $2 list file
  [ -f "$2" ] || return 1
  sed -e 's/#.*//' -e 's/[[:space:]]//g' "$2" | grep -qxF "$1"
}

# Overlay paths, relative to rails/, that docker-compose.yml mounts onto the live llamapress
# service — so the 0.8.0 boot in the scan sees the same code the box runs.
R8_OVERLAY_PATHS="app config/routes.rb db lib config/environments/development.rb config/database.yml \
config/importmap.rb config/initializers/devise.rb config/initializers/llama_bot_rails.rb \
config/initializers/session_cookie.rb config/initializers/custom config/locales config/storage.yml"

# Make sure the image is local. Pulling adds an image; it changes no file, container or DB.
r8_ensure_image() { # $1 image  $2 1=allow pull
  docker image inspect "$1" >/dev/null 2>&1 && return 0
  [ "$2" = "1" ] || return 1
  docker pull "$1" >/dev/null 2>&1
}

# Scan the overlay against the given image, in a throwaway container with NO network and every
# mount read-only. Two parts:
#   1. pattern scan of the overlay exactly as it is (what the CSV reports);
#   2. zeitwerk:check of the overlay AFTER the auto-fixes, applied to a scratch copy inside the
#      container. The old enum form crashes Rails 8 at load, so checking the raw overlay would
#      class every auto-fixable box needs_human. The box's own files are never written.
# Extra args go to `rails8_scan.rb report`.
r8_scan_overlay() { # $1 image, then report args
  local image="$1"; shift
  local -a info=()
  [ -f "$PROJECT_DIR/.leonardo/instance.json" ] &&
    info=(-v "$PROJECT_DIR/.leonardo/instance.json:/rails/.leonardo/instance.json:ro")
  docker run --rm --network none --entrypoint bash \
    -e RAILS_ENV=development -e SECRET_KEY_BASE=rails8-scan-not-a-secret \
    -e DATABASE_URL=postgres://scan@127.0.0.1:1/none -e R8_OVERLAY_PATHS="$R8_OVERLAY_PATHS" \
    -v "$PROJECT_DIR/rails:/overlay:ro" -v "$R8_SCANNER:/r8/rails8_scan.rb:ro" \
    "${info[@]}" "$image" -c '
      ruby /r8/rails8_scan.rb scan /overlay --gemfile-lock /rails/Gemfile.lock > /tmp/scan.json || exit 5
      cp -a /overlay /tmp/ov && ruby /r8/rails8_scan.rb apply /tmp/ov --gemfile-lock /rails/Gemfile.lock >/dev/null || exit 5
      for p in $R8_OVERLAY_PATHS; do
        [ -e "/tmp/ov/$p" ] || continue
        rm -rf "/rails/$p" && mkdir -p "$(dirname "/rails/$p")" && cp -a "/tmp/ov/$p" "/rails/$p" || exit 5
      done
      (cd /rails && timeout 300 bin/rails zeitwerk:check) > /tmp/zw.log 2>&1; echo $? > /tmp/zw.rc
      ruby /r8/rails8_scan.rb report /tmp/scan.json /tmp/zw.rc /tmp/zw.log "$@"
    ' r8 "$@"
}
