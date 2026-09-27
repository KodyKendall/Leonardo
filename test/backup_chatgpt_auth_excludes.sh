#!/usr/bin/env bash
#
# test/backup_chatgpt_auth_excludes.sh — the quick backup must not upload a customer's
# ChatGPT tokens, and codex's dangling symlinks must not break the source sync.
#
# The defect (leo-lozeki, 2026-09-24): with ChatGPT linked, codex keeps its state under
# .leonardo/chatgpt-auth/<user_id>/, including auth.json (OAuth tokens) and
# tmp/arg0/*/apply_patch etc., symlinks to a codex binary that exists only inside the
# llamabot container. The sync runs on the host, so every link dangles:
# "warning: Skipping file ... File does not exist." and aws exits 2. Every per-task
# backup on that box showed as failed; a successful one would have put auth.json in S3.
#
# Two flags are needed, and neither covers the other. Checked against the aws-cli v2
# FileGenerator source: it tests every path for existence BEFORE the --exclude filters
# run, so an exclude alone still warns and exits 2 on a dangling link. And
# --no-follow-symlinks drops links silently but still uploads auth.json. The stubbed
# `aws` below mirrors exactly that behaviour.
#
# Pure bash. No S3, no docker, no live app. Run: bash test/backup_chatgpt_auth_excludes.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/bin/backups/cloud/quick_backup.sh"
[ -f "$SCRIPT" ] || { echo "FATAL: $SCRIPT not found"; exit 2; }

fails=0
ok()  { echo "  PASS  $1"; }
no()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
eq()  { if [ "$1" = "$2" ]; then ok "$3"; else no "$3 (got '$1', want '$2')"; fi; }
has() { if printf '%s' "$1" | grep -q -- "$2"; then ok "$3"; else no "$3"; fi; }
hasnt() { if printf '%s' "$1" | grep -q -- "$2"; then no "$3"; else ok "$3"; fi; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/project/app" "$tmp/project/.leonardo/chatgpt-auth/1/tmp/arg0/codex-arg0abc"
echo "class A; end" > "$tmp/project/app/a.rb"
echo '{"tokens":"secret"}' > "$tmp/project/.leonardo/chatgpt-auth/1/auth.json"
ln -s /usr/local/lib/node_modules/@openai/codex/bin/codex-does-not-exist-on-host \
  "$tmp/project/.leonardo/chatgpt-auth/1/tmp/arg0/codex-arg0abc/apply_patch"

# A stub `aws s3 sync` that walks the tree the way the real one does: dangling links warn
# (exit 2) unless --no-follow-symlinks, and --exclude only affects what gets uploaded.
cat > "$tmp/bin/aws" <<'EOF'
#!/usr/bin/env bash
case "$1 $2" in
  "sts get-caller-identity") echo "123456789012 backup-user"; exit 0 ;;
  "s3 cp") cat > /dev/null; exit 0 ;;
  "s3 sync") ;;
  *) exit 0 ;;
esac
src="$3"; follow=1; excludes=()
shift 4
while [ $# -gt 0 ]; do
  case "$1" in
    --no-follow-symlinks) follow=0 ;;
    --exclude) excludes+=("$2"); shift ;;
  esac
  shift
done
[ "${src}" = "${src#*caddy}" ] || exit 0
rc=0
while IFS= read -r -d '' p; do
  rel="${p#"$src"/}"
  if [ -L "$p" ]; then
    [ "$follow" = 0 ] && continue
    [ -e "$p" ] || { echo "warning: Skipping file $p. File does not exist." >&2; rc=2; continue; }
  fi
  skip=0
  for e in "${excludes[@]}"; do
    # shellcheck disable=SC2053
    [[ "$rel" == $e ]] && skip=1
  done
  [ "$skip" = 0 ] && echo "$rel" >> "$UPLOAD_LOG"
done < <(find "$src" \( -type f -o -type l \) -print0)
exit $rc
EOF

cat > "$tmp/bin/docker" <<'EOF'
#!/usr/bin/env bash
echo "-- dump"
exit 0
EOF
chmod +x "$tmp/bin/aws" "$tmp/bin/docker"

UPLOAD_LOG="$tmp/uploaded.log" PATH="$tmp/bin:$PATH" \
  bash "$SCRIPT" test-instance "s3://bucket/test" "$tmp/project" > "$tmp/out.log" 2>&1
rc=$?
out="$(cat "$tmp/out.log")"
uploaded="$(cat "$tmp/uploaded.log" 2>/dev/null)"

echo "== ChatGPT credentials never leave the box =="
hasnt "$uploaded" "chatgpt-auth" "nothing under .leonardo/chatgpt-auth/ is uploaded"
hasnt "$uploaded" "auth.json"    "auth.json (the OAuth tokens) is not uploaded"
has   "$uploaded" "app/a.rb"     "ordinary project files are still uploaded"

echo
echo "== codex's dangling symlinks do not fail or warn the source step =="
hasnt "$out" "File does not exist" "no dangling-symlink warning from the sync"
has   "$out" "Step 1 — source code:          ✅ success" "step 1 reports a clean success"
eq    "$rc" "0" "the whole backup exits 0"

echo
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; exit 0; else echo "$fails FAILED"; exit 1; fi
