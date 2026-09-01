#!/usr/bin/env bash
#
# test/rails_watchdog.sh — regression tests for the wedged-Rails self-heal (SI#417).
#
# crm-4 served nothing from 11:43 to 11:53 MDT on 2026-08-31. The container reported
# "Up", the node was idle, Postgres was clean and TLS worked. Rails answered nothing,
# including its own /up. The Rails log stopped dead at 11:43:26 and never printed again.
#
# Cause: a dev-mode code reloader deadlock. Leo boxes run RAILS_ENV=development, so a file
# save triggers a class reload, the reload wants an exclusive lock, and a long-lived
# /cable WebSocket still held a shared one. Every later request blocked in
# ActionDispatch::Executor, which sits ABOVE the Rails logger — that is why the log goes
# silent rather than noisy.
#
# Docker restarts a container when the process EXITS, never when it is ALIVE but not
# answering. The /up healthcheck already detected this correctly and flipped the container
# to "unhealthy"; nothing consumed that signal, because restart policies ignore health
# outside Swarm. So the fix converts "alive but not serving" into "exited".
#
# This is a CLASS, not one bug: Puma thread exhaustion, the ActiveStorage Live thread
# leak, the Grover PDF wedge and the OOM husk all have the same shape.
#
# Pure bash. curl, pkill and sleep are stubbed. Run: bash test/rails_watchdog.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE="$REPO_ROOT/docker-compose.yml"
[ -f "$COMPOSE" ] || { echo "FATAL: $COMPOSE not found"; exit 2; }

fails=0
ok()  { echo "  PASS  $1"; }
no()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
chk() { if eval "$1"; then ok "$2"; else no "$2"; fi; }
ge()  { if [ "$1" -ge "$2" ] 2>/dev/null; then ok "$3"; else no "$3 (got '$1', want >= '$2')"; fi; }

echo "== MANDATORY GUARD: the health check must tolerate a slow dev-mode reload =="
#
# Measured on crm-4, 2026-08-31: a HEALTHY box took 10.045s to answer /up while / answered
# in 1.37s moments later. In development mode the first request after any file save pays
# the whole class reload, and the agent saves files all day. Making a 5-second timeout
# fatal would kill healthy servers, so the timeouts are raised BEFORE anything acts on
# the signal. A real wedge lasts forever; a long timeout still always catches it.

chk "grep -q -- '--max-time 25 http://127.0.0.1:3000/up' '$COMPOSE'" \
    "the healthcheck curl allows 25s, not 5s"
chk "! grep -q -- '--max-time 5 http' '$COMPOSE'" \
    "no 5-second health probe survives anywhere in the file"
chk "grep -qE '^\s+timeout: 30s' '$COMPOSE'" \
    "the healthcheck timeout is 30s, not 10s"

echo
echo "== The watchdog is present and shippable =="
#
# bin/ is not mounted into the container and rails/lib is not on the bin/update allowlist,
# so the watchdog has to live inline in docker-compose.yml — which IS on the allowlist and
# therefore reaches all 148 boxes on the next update push, with no image build.

chk "grep -q 'rails-watchdog' '$COMPOSE'" "the watchdog block is marked for extraction"
chk "grep -q 'pkill' '$COMPOSE'"          "the watchdog kills Puma so the retry loop can restart it"

# Extract the real shipped watchdog rather than a copy of it, so this test cannot drift.
WATCHDOG="$(sed -n '/>>> rails-watchdog >>>/,/<<< rails-watchdog <<</p' "$COMPOSE")"
if [ -z "$WATCHDOG" ]; then
  no "the watchdog block can be extracted from docker-compose.yml"
  echo; echo "$fails test(s) FAILED."; exit 1
fi
ok "the watchdog block can be extracted from docker-compose.yml"

case "$WATCHDOG" in
  *"--max-time 25"*) ok "the watchdog probe uses the same 25s timeout as the healthcheck" ;;
  *) no "the watchdog probe uses the same 25s timeout as the healthcheck" ;;
esac

echo
echo "== The watchdog actually kills Puma after repeated failures =="

tmp="$(mktemp -d)"
mkdir -p "$tmp/bin"

# Strip the YAML block indentation and un-escape compose's $$ so the shell can run it.
# The trailing `) &` becomes a plain `)` so the loop runs in the FOREGROUND: backgrounded,
# it would outlive `timeout` as an orphan and spin forever with the stubbed sleeps.
printf '%s\n' "$WATCHDOG" \
  | sed 's/^        //' \
  | sed 's/\$\$/$/g' \
  | sed 's/^) &$/)/' \
  | grep -v 'rails-watchdog' > "$tmp/watchdog.sh"

cat > "$tmp/bin/curl" <<'EOF'
#!/usr/bin/env bash
echo probe >> "$CALLS/curl.log"
exit 7          # the wedge: connection made, nothing ever answers
EOF
cat > "$tmp/bin/pkill" <<'EOF'
#!/usr/bin/env bash
echo "kill $*" >> "$CALLS/pkill.log"
exit 0
EOF
# Real sleeps would make this test take minutes; the logic under test is the counting.
cat > "$tmp/bin/sleep" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$tmp/bin/curl" "$tmp/bin/pkill" "$tmp/bin/sleep"

CALLS="$tmp" PATH="$tmp/bin:$PATH" timeout -k 1 3 bash "$tmp/watchdog.sh" >/dev/null 2>&1
pkill -f "$tmp/watchdog.sh" 2>/dev/null || true   # belt and braces

KILLS=$(wc -l < "$tmp/pkill.log" 2>/dev/null || echo 0)
PROBES=$(wc -l < "$tmp/curl.log" 2>/dev/null || echo 0)

ge "$KILLS" 1 "an unanswering /up eventually kills Puma"
ge "$PROBES" 3 "it probes repeatedly before killing, rather than on the first miss"
# Three consecutive failures per kill: a single slow answer must never trigger a restart.
chk "[ \"$PROBES\" -ge \$(( KILLS * 3 )) ]" \
    "each kill costs at least 3 consecutive failed probes (no single-miss restarts)"

rm -rf "$tmp"

echo
echo "== The self-heal must not silently spend the restart budget =="
#
# PUMA_MAX_RESTARTS defaults to 3 and counts every exit for the LIFE of the container,
# not per incident. Without this, three watchdog kills over three separate days would
# park the box in `tail -f /dev/null` — "Up", and serving nothing, permanently.

chk "grep -q 'HEALTHY_RUN_SECONDS' '$COMPOSE'" \
    "a sustained healthy run resets the restart budget"

echo
if [ "$fails" -eq 0 ]; then
  echo "All rails watchdog tests passed."
  exit 0
fi
echo "$fails test(s) FAILED."
exit 1
