#!/usr/bin/env bash
#
# test/rails_public_rescue.sh — before the first recreate on a compose that bind-mounts
# the whole rails/public/, bin/update must copy the files Leo wrote into the container
# layer out to the host, or the recreate throws them away.
#
# The defect (leo-reare, 2026-09-24): only rails/public/uploads was mounted, so the icons
# Leo made for the app lived in the container layer and every recreate brought the stock
# red square back. The customer asked Leo to fix it five times in six weeks.
#
# Only files that DIFFER from the image (`docker diff` A/C entries) are rescued: copying
# every file would write the old stock icon to the host, and the entrypoint's no-clobber
# seed would then keep it forever.
#
# Pure bash; docker is stubbed on PATH. Run: bash test/rails_public_rescue.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$REPO_ROOT/bin/lib/rails_public_rescue.sh"
[ -f "$LIB" ] || { echo "FATAL: $LIB not found"; exit 2; }

fails=0
ok()  { echo "  PASS  $1"; }
no()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
chk() { if eval "$1"; then ok "$2"; else no "$2"; fi; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# $1 = mounts the running container already has (newline-separated destinations)
# $2 = compose volume line for rails/public
setup() {
  local mounts="$1" compose_line="$2"
  rm -rf "$WORK/box" "$WORK/bin" "$WORK/container"
  mkdir -p "$WORK/box/rails/public/uploads" "$WORK/bin" "$WORK/container/rails/public/uploads" \
           "$WORK/container/rails/public/icons"
  printf 'services:\n  llamapress:\n    volumes:\n      - %s\n' "$compose_line" > "$WORK/box/docker-compose.yml"
  echo "host-only manifest" > "$WORK/box/rails/public/manifest.json"
  echo "host copy Leo wrote, never served" > "$WORK/box/rails/public/icon.svg"

  # What is inside the running container's /rails/public.
  echo "purple school icon" > "$WORK/container/rails/public/icon.svg"
  echo "purple png"         > "$WORK/container/rails/public/icon-192.png"
  echo "stock 404"          > "$WORK/container/rails/public/404.html"
  echo "stock red square"   > "$WORK/container/rails/public/icon.png"
  echo "nested"             > "$WORK/container/rails/public/icons/a.png"
  echo "customer upload"    > "$WORK/container/rails/public/uploads/u.jpg"
  printf '%s\n' "$mounts" > "$WORK/mounts"

  cat > "$WORK/bin/docker" <<EOF
#!/usr/bin/env bash
C="$WORK/container"
case "\$1" in
  inspect) cat "$WORK/mounts" ;;
  diff) printf '%s\n' \
      "C /rails/public" \
      "C /rails/public/icon.svg" \
      "A /rails/public/icon-192.png" \
      "A /rails/public/icons" \
      "A /rails/public/icons/a.png" \
      "A /rails/public/uploads/u.jpg" \
      "C /rails/tmp" ;;
  exec) shift 2; [ "\$1" = test ] && [ "\$2" = -f ] && [ -f "\$C\$3" ] ;;
  cp) src="\${2#*:}"; cp "\$C\$src" "\$3" ;;
  *) exit 0 ;;
esac
EOF
  chmod +x "$WORK/bin/docker"
}

run_rescue() {
  (
    PATH="$WORK/bin:$PATH"
    PROJECT_DIR="$WORK/box"; COMPOSE_FILE="docker-compose.yml"; LOG="$WORK/log"
    log() { echo "$*" >> "$LOG"; }
    # shellcheck source=/dev/null
    . "$LIB"
    rescue_rails_public "container123"
  )
}

pub="$WORK/box/rails/public"

echo "== first recreate onto the whole-directory mount =="
setup "/rails/public/uploads" "./rails/public:/rails/public:delegated"
run_rescue
chk '[ "$(cat "$pub/icon.svg")" = "purple school icon" ]' "the icon being SERVED wins over the host copy that never was"
chk '[ "$(cat "$pub/icon-192.png")" = "purple png" ]'     "an icon Leo added in the container reaches the host"
chk '[ "$(cat "$pub/icons/a.png")" = "nested" ]'          "a file in a subdirectory Leo added is rescued"
chk '[ ! -e "$pub/icon.png" ]'                            "an unchanged stock file is NOT copied (it would pin the red square)"
chk '[ ! -e "$pub/404.html" ]'                            "stock pages are left to the entrypoint seed"
chk '[ ! -e "$pub/uploads/u.jpg" ]'                       "uploads are already on the host mount and are skipped"
chk '[ "$(cat "$pub/manifest.json")" = "host-only manifest" ]' "host-only files are untouched"

echo
echo "== already on the new mount: nothing lives only in the container =="
setup "$(printf '/rails/public\n/rails/public/uploads')" "./rails/public:/rails/public:delegated"
run_rescue
chk '[ "$(cat "$pub/icon.svg")" = "host copy Leo wrote, never served" ]' "no copy when /rails/public is already mounted"

echo
echo "== compose does not mount rails/public yet =="
setup "/rails/public/uploads" "./rails/public/uploads:/rails/public/uploads:delegated"
run_rescue
chk '[ ! -e "$pub/icon-192.png" ]' "no copy until the compose actually mounts the whole directory"

echo
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; exit 0; else echo "$fails FAILED"; exit 1; fi
