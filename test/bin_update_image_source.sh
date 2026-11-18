#!/usr/bin/env bash
#
# test/bin_update_image_source.sh — LP-51: bin/update's opt-in IMAGE_SOURCE=registry pull
# from registry.llamapress.ai, with a per-service Docker Hub fallback.
#
# A mock docker records every call so we can assert which source each image came from,
# what the marker says, and that the box license key never lands in argv, the log, .env,
# the marker or ~/.docker/config.json. Pure bash; no docker, no network.
# Run: bash test/bin_update_image_source.sh
#
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPDATE="$REPO_ROOT/bin/update"
RECREATE="$REPO_ROOT/bin/lib/update_recreate.sh"
[ -f "$UPDATE" ] || { echo "FATAL: $UPDATE not found"; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok()  { echo "  PASS  $1"; }
no()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
chk() { if eval "$1"; then ok "$2"; else no "$2"; fi; }

export MIGRATE_MAX_RETRIES=1 MIGRATE_RETRY_SLEEP_SEC=0
KEY="lk_SECRET_box_key_9f8e7d"
REG="registry.llamapress.ai"
mock_bin="$WORK/mock_bin"; mkdir -p "$mock_bin"
FAKE_HOME="$WORK/home"; mkdir -p "$FAKE_HOME"

# ---- mock docker ----------------------------------------------------------------
# Knobs (files in $st): login_fail, notfound_<image>, hang, digest_bad, hub_fail.
cat > "$mock_bin/docker" <<'DOCKEREOF'
#!/usr/bin/env bash
st="$MOCK_STATE"
echo "$*" >> "$st/calls"
case "$*" in
  "compose version") exit 0 ;;
  "compose exec -T llamapress"*) exit 0 ;;
  "compose ps -q llamabot") echo cid_llamabot ;;
  "compose ps -q llamapress") echo cid_llamapress ;;
  "inspect --format {{.Config.Image}} cid_llamabot") echo "kody06/llamabot:1.0.0" ;;
  "inspect --format {{.Config.Image}} cid_llamapress") echo "kody06/llamapress-simple:2.0.0" ;;
  "login "*)
    cat > "$st/login_stdin"
    echo "${DOCKER_CONFIG:-}" > "$st/login_docker_config"
    [ -f "$st/login_fail" ] && { echo "Error response from daemon: unauthorized: invalid license key" >&2; exit 1; }
    [ -n "${DOCKER_CONFIG:-}" ] && echo '{"auths":{"registry.llamapress.ai":{"auth":"x"}}}' > "$DOCKER_CONFIG/config.json"
    echo "Login Succeeded"; exit 0 ;;
  "logout "*) echo "${DOCKER_CONFIG:-}" > "$st/logout_docker_config"; exit 0 ;;
  "pull registry.llamapress.ai/"*)
    img="${2#registry.llamapress.ai/llamapress/}"; name="${img%%:*}"
    [ -f "$st/hang" ] && exec sleep 30   # exec: one process, like the real docker CLI
    [ -f "$st/notfound_$name" ] && { echo "Error response from daemon: manifest for $2 not found: manifest unknown" >&2; exit 1; }
    echo "${img#*:}: Pulling from llamapress/$name"
    echo "Digest: sha256:aaaa$name"
    echo "Status: Downloaded newer image for $2"; exit 0 ;;
  "image inspect -f {{json .RepoDigests}} registry.llamapress.ai/"*)
    name="${5#registry.llamapress.ai/llamapress/}"; name="${name%%:*}"
    if [ -f "$st/digest_bad" ]; then echo "[\"$REG/llamapress/$name@sha256:bbbb\"]"
    else echo "[\"registry.llamapress.ai/llamapress/$name@sha256:aaaa$name\"]"; fi ;;
  "tag "*|"rmi "*) exit 0 ;;
  "compose pull"*)
    [ -f "$st/hub_fail" ] && { echo "Error response from daemon: Get https://registry-1.docker.io/v2/: dial tcp: lookup registry-1.docker.io: no such host" >&2; exit 1; }
    exit 0 ;;
  "compose up -d"*|"image prune -af"|"ps -a --format {{.Names}}") exit 0 ;;
  *) exit 1 ;;
esac
DOCKEREOF
chmod +x "$mock_bin/docker"
printf '#!/usr/bin/env bash\nexec "$@"\n' > "$mock_bin/sudo"
cat > "$mock_bin/systemd-run" <<'SDEOF'
#!/usr/bin/env bash
for ((i=1; i<=$#; i++)); do
  if [ "${!i}" = "-c" ]; then j=$((i+1)); bash -c "${!j}"; exit $?; fi
done
exit 1
SDEOF
printf '#!/usr/bin/env bash\nexit 0\n' > "$mock_bin/systemctl"
chmod +x "$mock_bin/sudo" "$mock_bin/systemd-run" "$mock_bin/systemctl"

# ---- a box: no upstream remote (sync skips), literal tags, old images running ----
box="$WORK/box"
mkdir -p "$box/bin/lib" "$box/.leonardo" && cd "$box"
git init -q -b main && git config user.email t@t && git config user.name t
cp "$UPDATE" bin/update && cp "$RECREATE" bin/lib/
printf '{"instance_name": "box-from-instance-json"}\n' > .leonardo/instance.json
echo "SOME_SETTING=1" > .env
git add -A && git commit -qm init

run() { # $1 state dir, then env assignments; runs bin/update 1.2.3 2.3.4
  local st="$1"; shift
  mkdir -p "$st"; : > "$st/calls"
  printf 'services:\n  llamabot:\n    image: kody06/llamabot:1.0.0\n  llamapress:\n    image: kody06/llamapress-simple:2.0.0\n' > docker-compose.yml
  : > .leonardo/update.log
  env HOME="$FAKE_HOME" PATH="$mock_bin:$PATH" MOCK_STATE="$st" "$@" bash bin/update 1.2.3 2.3.4 >"$st/out" 2>&1
  echo $? > "$st/rc"
}
marker_has() { python3 -c 'import json,sys; m=json.load(open(".leonardo/last_update.json")); print(json.dumps(m.get("image_sources")))' | grep -qF "$1"; }
src_of() { # $1 svc -> prints "source reason"
  python3 -c 'import json,sys; s=json.load(open(".leonardo/last_update.json"))["image_sources"][sys.argv[1]]; print(s["image_source"], s.get("fallback_reason",""))' "$1"
}
no_key_anywhere() { # $1 state dir
  ! grep -rqF "$KEY" .env .leonardo/ "$1/calls" "$FAKE_HOME" 2>/dev/null
}

echo "== A: IMAGE_SOURCE unset -> today's single compose pull, no registry login =="
sA="$WORK/A"; run "$sA"
chk 'grep -qx "compose pull llamabot llamapress" "$sA/calls"'    "one compose pull for all changed services"
chk '! grep -q "^login\|^pull registry\|^logout" "$sA/calls"'    "no registry login/pull/logout attempted"
chk 'grep -q "image_source=dockerhub" .leonardo/update.log'       "log says image_source=dockerhub"
chk '[ "$(src_of llamabot)" = "dockerhub " ] && [ "$(src_of llamapress)" = "dockerhub " ]' "marker records dockerhub per service, no fallback_reason"
chk 'grep -q "\"status\": \"success\"" .leonardo/last_update.json' "update succeeds"

echo "== B: unknown IMAGE_SOURCE=foo is the default path =="
sB="$WORK/B"; run "$sB" IMAGE_SOURCE=foo BOX_LICENSE_KEY="$KEY"
chk 'grep -qx "compose pull llamabot llamapress" "$sB/calls"'    "same single compose pull"
chk '! grep -q "^login" "$sB/calls"'                              "no login even with a key present"
chk '[ "$(src_of llamabot)" = "dockerhub " ]'                     "marker records dockerhub"

echo "== C: IMAGE_SOURCE=registry with a valid key -> registry, retagged, logged out =="
sC="$WORK/C"; run "$sC" IMAGE_SOURCE=registry BOX_LICENSE_KEY="$KEY" DNS_NAME=leo-box-7
chk 'grep -qx "login $REG -u leo-box-7 --password-stdin" "$sC/calls"' "login uses DNS_NAME and --password-stdin"
chk '[ "$(cat "$sC/login_stdin")" = "$KEY" ]'                     "key reaches docker login on stdin"
chk 'grep -qx "pull $REG/llamapress/llamabot:1.2.3" "$sC/calls"'  "llamabot pulled from registry"
chk 'grep -qx "pull $REG/llamapress/llamapress-simple:2.3.4" "$sC/calls"' "llamapress-simple pulled from registry"
chk 'grep -qx "tag $REG/llamapress/llamabot:1.2.3 kody06/llamabot:1.2.3" "$sC/calls"' "retagged to kody06/ name compose uses"
chk 'grep -qx "rmi $REG/llamapress/llamapress-simple:2.3.4" "$sC/calls"' "registry tag removed after retag"
chk '! grep -q "^compose pull" "$sC/calls"'                       "Docker Hub not touched"
chk 'grep -q "^logout $REG" "$sC/calls"'                          "docker logout ran"
chk '[ "$(src_of llamabot)" = "registry " ] && [ "$(src_of llamapress)" = "registry " ]' "marker records image_source=registry"
chk 'grep -q "image_source=registry" .leonardo/update.log'        "log says image_source=registry"
chk 'grep -q "\"status\": \"success\"" .leonardo/last_update.json' "update succeeds"
cfg="$(cat "$sC/login_docker_config")"
chk '[ -n "$cfg" ] && [ "$cfg" != "$FAKE_HOME/.docker" ] && [ ! -e "$cfg" ]' "login used a throwaway DOCKER_CONFIG, deleted afterwards"
chk 'no_key_anywhere "$sC"'                                       "key not in argv, .env, .leonardo/, or ~/.docker"

echo "== C2: no DNS_NAME -> box name from instance.json =="
sC2="$WORK/C2"; run "$sC2" IMAGE_SOURCE=registry BOX_LICENSE_KEY="$KEY"
chk 'grep -qx "login $REG -u box-from-instance-json --password-stdin" "$sC2/calls"' "login user falls back to instance_name"

echo "== D: registry, no key -> Docker Hub, fallback_reason=no_key =="
sD="$WORK/D"; run "$sD" IMAGE_SOURCE=registry
chk '! grep -q "^login" "$sD/calls"'                              "no login without a key"
chk 'grep -qx "compose pull llamabot" "$sD/calls" && grep -qx "compose pull llamapress" "$sD/calls"' "each service pulled from Docker Hub"
chk '[ "$(src_of llamabot)" = "dockerhub no_key" ]'               "marker: dockerhub + no_key"
chk 'grep -q "fallback_reason=no_key" .leonardo/update.log'       "log carries the fallback reason"
chk 'grep -q "\"status\": \"success\"" .leonardo/last_update.json' "update succeeds"

echo "== E: revoked key -> login_failed, still succeeds, still logged out =="
sE="$WORK/E"; mkdir -p "$sE"; touch "$sE/login_fail"
run "$sE" IMAGE_SOURCE=registry BOX_LICENSE_KEY="$KEY" DNS_NAME=leo-box-7
chk 'src_of llamabot | grep -q "^dockerhub login_failed"'         "marker: dockerhub + login_failed"
chk '! grep -q "^pull $REG" "$sE/calls"'                          "no registry pull after a failed login"
chk 'grep -q "\"status\": \"success\"" .leonardo/last_update.json' "update succeeds via Docker Hub"
chk '[ ! -e "$(cat "$sE/login_docker_config")" ]'                 "throwaway DOCKER_CONFIG removed after failure"
chk 'no_key_anywhere "$sE"'                                       "key left nowhere"

echo "== F: per-service fallback — llamabot tag not mirrored =="
sF="$WORK/F"; mkdir -p "$sF"; touch "$sF/notfound_llamabot"
run "$sF" IMAGE_SOURCE=registry BOX_LICENSE_KEY="$KEY" DNS_NAME=leo-box-7
chk '[ "$(src_of llamapress)" = "registry " ]'                    "llamapress from registry"
chk '[ "$(src_of llamabot)" = "dockerhub tag_not_found" ]'        "llamabot dockerhub + tag_not_found"
chk 'grep -qx "compose pull llamabot" "$sF/calls" && ! grep -qx "compose pull llamapress" "$sF/calls"' "only llamabot hits Docker Hub"

echo "== G: hung registry -> timeout, falls back =="
sG="$WORK/G"; mkdir -p "$sG"; touch "$sG/hang"
start=$(date +%s)
run "$sG" IMAGE_SOURCE=registry BOX_LICENSE_KEY="$KEY" DNS_NAME=leo-box-7 REGISTRY_PULL_TIMEOUT_SEC=1
chk '[ $(( $(date +%s) - start )) -lt 20 ]'                       "pull stopped by the timeout"
chk '[ "$(src_of llamabot)" = "dockerhub timeout" ]'              "marker: dockerhub + timeout"
chk 'grep -q "\"status\": \"success\"" .leonardo/last_update.json' "update succeeds"

echo "== H: digest mismatch -> falls back =="
sH="$WORK/H"; mkdir -p "$sH"; touch "$sH/digest_bad"
run "$sH" IMAGE_SOURCE=registry BOX_LICENSE_KEY="$KEY" DNS_NAME=leo-box-7
chk '[ "$(src_of llamabot)" = "dockerhub digest_mismatch" ]'      "marker: dockerhub + digest_mismatch"
chk '! grep -q "^tag $REG" "$sH/calls"'                           "mismatched image never retagged"

echo "== I: both sources fail -> update fails with both reasons =="
sI="$WORK/I"; mkdir -p "$sI"; touch "$sI/notfound_llamabot" "$sI/notfound_llamapress-simple" "$sI/hub_fail"
run "$sI" IMAGE_SOURCE=registry BOX_LICENSE_KEY="$KEY" DNS_NAME=leo-box-7
chk '[ "$(cat "$sI/rc")" -ne 0 ]'                                 "bin/update exits non-zero"
chk 'grep -q "\"status\": \"failed\"" .leonardo/last_update.json' "marker says failed"
chk 'grep -q "registry=tag_not_found" .leonardo/update.log && grep -q "dockerhub=.*no such host" .leonardo/update.log' "log shows both reasons"
chk 'grep -q "^logout $REG" "$sI/calls"'                          "logout still ran on failure"
chk '! grep -q "^compose up" "$sI/calls"'                         "no recreate after a failed pull"
chk 'no_key_anywhere "$sI"'                                       "key left nowhere"

echo
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; else echo "$fails FAILED"; fi
exit "$fails"
