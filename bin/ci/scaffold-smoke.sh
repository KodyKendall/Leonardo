#!/usr/bin/env bash
# Scaffold smoke: prove that a plain `bin/rails generate scaffold` inside the
# SHIPPING llamapress container applies the LlamaPress scaffold templates
# (llama_bot_rails gem) and renders the drawer/table index. This is the true
# CLI path Leo's bash_rails tool uses — if template registration breaks in the
# image, this fails.
#
# Runs against an already-started compose stack (see the e2e-smoke CI job).
# Cleans up after itself even on failure: rollback BEFORE destroy so the
# migration file still exists when db:rollback needs it.
set -euo pipefail

COMPOSE_FILE="${E2E_COMPOSE_FILE:-docker-compose.yml}"
RESOURCE="E2eProbeContact"
INDEX_URL="http://localhost:3000/e2e_probe_contacts"

rails_cmd() {
  docker compose -f "$COMPOSE_FILE" exec -T llamapress bin/rails "$@"
}

cleanup() {
  set +e
  rails_cmd db:rollback STEP=1
  rails_cmd destroy scaffold "$RESOURCE"
}
trap cleanup EXIT

echo "--- generate scaffold ${RESOURCE}"
rails_cmd generate scaffold "$RESOURCE" name:string email:string company:string status:string notes:text
rails_cmd db:migrate

echo "--- fetch ${INDEX_URL}"
body=$(curl -sf "$INDEX_URL")

fail() { echo "::error::scaffold smoke: $1"; exit 1; }

echo "$body" | grep -q 'id="record_drawer"' \
  || fail "record_drawer frame missing from index (templates not applied?)"
echo "$body" | grep -q 'data-controller="filter-panel"' \
  || fail "filter panel missing from index"
echo "$body" | grep -q 'controllers/record_drawer_controller' \
  || fail "record_drawer Stimulus controller not pinned in importmap"
if echo "$body" | grep -q '>Notes<'; then
  fail "notes:text leaked into the table columns"
fi

echo "scaffold smoke OK: LlamaPress templates applied by plain rails generate"
