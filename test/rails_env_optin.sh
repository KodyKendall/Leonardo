#!/usr/bin/env bash
#
# test/rails_env_optin.sh — fleet-shared AWS and DeepSeek keys must be blank in the
# Rails container unless the box opts in with RAILS_<NAME> in its .env (0.7.14).
#
# The defect (fleet sweep, 2026-10-14): llamapress loads the whole .env, and the
# shared S3 backup key (bucket-scoped, so it can read OTHER tenants' backups) and
# our shared DeepSeek key were never blanked. Anything running in the Rails
# container — Leo's shell, the MCP run_shell_command tool, customer code — could
# printenv them. 13 boxes call DeepSeek from Rails and 2 use the AWS key for
# Active Storage, so those opt back in with e.g. RAILS_DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}.
#
# Resolves the real docker-compose.yml with `docker compose config` against a fake
# .env. No containers are started. Run: bash test/rails_env_optin.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE="$REPO_ROOT/docker-compose.yml"
[ -f "$COMPOSE" ] || { echo "FATAL: $COMPOSE not found"; exit 2; }
docker compose version >/dev/null 2>&1 || { echo "FATAL: docker compose not available"; exit 2; }

fails=0
ok()  { echo "  PASS  $1"; }
no()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
eq()  { if [ "$1" = "$2" ]; then ok "$3"; else no "$3 (got '$1', want '$2')"; fi; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp "$COMPOSE" "$tmp/docker-compose.yml"

# env <service> <NAME> — the value compose resolves for that service.
env_of() {
  docker compose --project-directory "$tmp" -f "$tmp/docker-compose.yml" config --format json 2>/dev/null \
    | python3 -c "import json,sys; print((json.load(sys.stdin)['services']['$1'].get('environment') or {}).get('$2', '<unset>'))"
}

BASE_ENV='AWS_ACCESS_KEY_ID=akid-shared
AWS_SECRET_ACCESS_KEY=secret-shared
DEEPSEEK_API_KEY=ds-shared'

echo "no opt-in:"
printf '%s\n' "$BASE_ENV" > "$tmp/.env"
eq "$(env_of llamapress AWS_ACCESS_KEY_ID)"     ""             "llamapress AWS_ACCESS_KEY_ID is blank"
eq "$(env_of llamapress AWS_SECRET_ACCESS_KEY)" ""             "llamapress AWS_SECRET_ACCESS_KEY is blank"
eq "$(env_of llamapress DEEPSEEK_API_KEY)"      ""             "llamapress DEEPSEEK_API_KEY is blank"
eq "$(env_of llamabot AWS_ACCESS_KEY_ID)"       "akid-shared"  "llamabot keeps AWS_ACCESS_KEY_ID"
eq "$(env_of llamabot DEEPSEEK_API_KEY)"        "ds-shared"    "llamabot keeps DEEPSEEK_API_KEY"

echo "opted in (the line the mothership writes on a box that needs it):"
printf '%s\n%s\n' "$BASE_ENV" 'RAILS_DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
RAILS_AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
RAILS_AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}' > "$tmp/.env"
eq "$(env_of llamapress DEEPSEEK_API_KEY)"      "ds-shared"     "llamapress gets DEEPSEEK_API_KEY when opted in"
eq "$(env_of llamapress AWS_ACCESS_KEY_ID)"     "akid-shared"   "llamapress gets AWS_ACCESS_KEY_ID when opted in"
eq "$(env_of llamapress AWS_SECRET_ACCESS_KEY)" "secret-shared" "llamapress gets AWS_SECRET_ACCESS_KEY when opted in"

if grep -n 'RAILS_\(AWS\|DEEPSEEK\)' <(awk '/^  llamabot:/,/^  db:/' "$COMPOSE") >/dev/null; then
  no "llamabot service must not reference the RAILS_ opt-ins"
else
  ok "llamabot service has no RAILS_ opt-in override"
fi

echo
[ "$fails" -eq 0 ] && { echo "ALL PASS"; exit 0; } || { echo "$fails FAILED"; exit 1; }
