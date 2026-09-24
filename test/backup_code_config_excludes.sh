#!/usr/bin/env bash
#
# test/backup_code_config_excludes.sh — the code_config volume backup must skip caches
# and the Claude Code extension versions code-server has already marked obsolete.
#
#  The defect: step 2 tarred the whole code-server /config volume. Every extension
#  auto-update leaves the previous ~140 MB version behind (listed in
#  extensions/.obsolete, deleted only on a restart that never comes) plus a VSIX
#  download cache. Volumes reached 4-5 GB, the gzip ate the shared 900 s backup budget,
#  three timeouts auto-disabled backups (lohman-dev, leo-mezuli, rsb-dev; 2026-09-22).
#
# Pure bash. No S3, no docker, no live app. Run: bash test/backup_code_config_excludes.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$REPO_ROOT/bin/backups/cloud/lib/code_config_excludes.sh"
[ -f "$LIB" ] || { echo "FATAL: $LIB not found"; exit 2; }
# shellcheck source=/dev/null
. "$LIB"

fails=0
ok()  { echo "  PASS  $1"; }
no()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
has() { case " $1 " in *" $2 "*) ok "$3";; *) no "$3 (missing '$2' in '$1')";; esac; }
hasnt() { case " $1 " in *" $2 "*) no "$3 (unexpected '$2' in '$1')";; *) ok "$3";; esac; }
lacks() { case "$1" in *"$2"*) no "$3 (unexpected '$2' in '$1')";; *) ok "$3";; esac; }

# The shape found on lohman prod: extensions.json references only 2.1.278, .obsolete
# lists the older versions.
OBSOLETE='{"anthropic.claude-code-2.1.250-linux-x64":true,"anthropic.claude-code-2.1.263-linux-x64":true, "anthropic.claude-code-2.1.270-linux-x64" : true}'
IN_USE='[{"identifier":{"id":"anthropic.claude-code"},"version":"2.1.278","location":{"$mid":1,"path":"/config/extensions/anthropic.claude-code-2.1.278-linux-x64"},"relativeLocation":"anthropic.claude-code-2.1.278-linux-x64"}]'

echo "== caches are always excluded =="
out="$(code_config_tar_excludes "" "")"
has   "$out" "--exclude=./data/CachedExtensionVSIXs" "the VSIX download cache"
has   "$out" "--exclude=./data/logs"                 "code-server logs"
has   "$out" "--exclude=./.npm/_cacache"              "the npm cache"
hasnt "$out" "--exclude=./extensions/.obsolete"       "the .obsolete list itself is KEPT, so a restore still knows what to delete"

echo
echo "== obsolete extension versions are excluded =="
out="$(code_config_tar_excludes "$OBSOLETE" "$IN_USE")"
has "$out" "--exclude=./extensions/anthropic.claude-code-2.1.250-linux-x64" "an obsolete version"
has "$out" "--exclude=./extensions/anthropic.claude-code-2.1.270-linux-x64" "one written with spaces around the colon"

echo
echo "== the extension actually in use is never excluded =="
out="$(code_config_tar_excludes '{"anthropic.claude-code-2.1.278-linux-x64":true}' "$IN_USE")"
hasnt "$out" "--exclude=./extensions/anthropic.claude-code-2.1.278-linux-x64" \
      "a dir named in extensions.json survives even if .obsolete lists it"

echo
echo "== .obsolete is not trusted to name paths =="
out="$(code_config_tar_excludes '{"../../etc":true,"a/b":true,"*":true,"ok-1.0":false}' "")"
hasnt "$out" "--exclude=./extensions/../../etc" "a parent-dir escape"
hasnt "$out" "--exclude=./extensions/a/b"       "a nested path"
hasnt "$out" "--exclude=./extensions/*"         "a glob that would drop every extension"
hasnt "$out" "--exclude=./extensions/ok-1.0"    "an entry marked false"

echo
echo "== a missing or garbled .obsolete only skips the extension excludes =="
out="$(code_config_tar_excludes "not json at all" "")"
has   "$out" "--exclude=./data/CachedExtensionVSIXs" "caches still excluded"
lacks "$out" "--exclude=./extensions/" "no extension excludes invented"

echo
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; exit 0; else echo "$fails FAILED"; exit 1; fi
