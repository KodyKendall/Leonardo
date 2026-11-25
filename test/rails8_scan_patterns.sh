#!/usr/bin/env bash
#
# test/rails8_scan_patterns.sh — LP-52: bin/lib/rails8_scan.rb classifies overlay code that
# Rails 8.1 / Ruby 3.4 removed (auto-fix vs needs-a-human) and its codemods fix the auto ones.
#
# Builds a throwaway overlay with one of each pattern, scans it, applies the codemods, and
# rescans. Needs a Ruby: `ruby` on PATH (GitHub runners have one), else RUBY="docker run ...".
# Run: bash test/rails8_scan_patterns.sh
#
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAN="$REPO_ROOT/bin/lib/rails8_scan.rb"
[ -f "$SCAN" ] || { echo "FATAL: $SCAN not found"; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok()  { echo "  PASS  $1"; }
no()  { echo "  FAIL  $1"; fails=$((fails + 1)); }
chk() { if eval "$1"; then ok "$2"; else no "$2"; fi; }

if [ -n "${RUBY:-}" ]; then :
elif command -v ruby >/dev/null 2>&1; then RUBY="ruby"
else RUBY="docker run --rm -v $WORK:$WORK -v $SCAN:$SCAN:ro ruby:3.4-bookworm ruby"; fi
scan() { $RUBY "$SCAN" "$@"; }

O="$WORK/rails"
mkdir -p "$O/app/models" "$O/app/controllers/users" "$O/config/environments" "$O/config/initializers" "$O/lib" "$O/db"

cat > "$O/app/models/order.rb" <<'RB'
class Order < ApplicationRecord
  enum status: { pending: 0, paid: 1 }, _prefix: true
  enum :kind, { a: 0, b: 1 }
  enum size: [:small, :large]
  enum tier: {
    free: 0,
    pro: 1
  }, _suffix: :tier
end
RB
cat > "$O/app/models/both.rb" <<'RB'
class Both < ApplicationRecord
  enum color: { red: 0 }, shape: { round: 0 }
end
RB
cat > "$O/lib/proxy.rb" <<'RB'
class Proxy < ActiveSupport::ProxyObject
end
RB
cat > "$O/config/environments/development.rb" <<'RB'
Rails.application.configure do
  config.read_encrypted_secrets = true
  config.active_record.warn_on_records_fetched_greater_than = 500
  config.eager_load = false
end
RB
cat > "$O/config/initializers/keys.rb" <<'RB'
STRIPE_KEY = Rails.application.secrets.stripe_key
RB
cat > "$O/app/controllers/users/sessions_controller.rb" <<'RB'
class Users::SessionsController < Devise::SessionsController
end
RB
# The STOCK Leonardo Devise overrides ship on every box and are tested on Devise 5 (overlay
# specs); byte-identical copies must not flag the whole fleet. An edited copy still does.
cp "$REPO_ROOT/rails/app/controllers/users/registrations_controller.rb" "$O/app/controllers/users/"
mkdir -p "$O/app/controllers/admin"
{ cat "$REPO_ROOT/rails/app/controllers/users/registrations_controller.rb"; echo "# customer edit"; } \
  > "$O/app/controllers/admin/registrations_controller.rb"
cat > "$O/lib/watcher.rb" <<'RB'
require "observer"
require "csv"
RB
cat > "$O/config/routes.rb" <<'RB'
Rails.application.routes.draw do
end
RB
# A lockfile that has csv but not observer, like the 0.8.0 image.
cat > "$WORK/Gemfile.lock" <<'LOCK'
GEM
  specs:
    csv (3.3.7)
    rails (8.1.4.1)
LOCK

echo "== scan"
out="$(scan scan "$O" --gemfile-lock "$WORK/Gemfile.lock")"; rc=$?
echo "$out" > "$WORK/scan.json"
chk '[ $rc -eq 0 ]' "scan exits 0"
has() { # $1 auto|human  $2 pattern  $3 file suffix
  $RUBY -rjson -e 'd=JSON.parse(File.read(ARGV[0])); exit(d[ARGV[1]].any?{|f| f["pattern"]==ARGV[2] && f["file"].end_with?(ARGV[3])} ? 0 : 1)' \
    "$WORK/scan.json" "$1" "$2" "$3"
}
count() { $RUBY -rjson -e 'd=JSON.parse(File.read(ARGV[0])); puts d[ARGV[1]].size' "$WORK/scan.json" "$1"; }

chk 'has auto enum_keyword_form app/models/order.rb'          "old enum form is an auto-fix"
chk '[ "$(grep -c enum_keyword_form "$WORK/scan.json")" -ge 1 ]' "enum pattern named in output"
chk 'has human enum_multiple_in_one_call app/models/both.rb'  "two enums in one call need a human"
chk 'has auto proxy_object lib/proxy.rb'                       "ActiveSupport::ProxyObject is an auto-fix"
chk 'has auto removed_config config/environments/development.rb' "removed config key is an auto-fix"
chk 'has human application_secrets config/initializers/keys.rb' "Rails.application.secrets needs a human"
chk 'has human devise_controller_override app/controllers/users/sessions_controller.rb' "Devise controller override needs a human"
chk '! has human devise_controller_override app/controllers/users/registrations_controller.rb' "stock Devise override (byte-identical) is not flagged"
chk 'has human devise_controller_override app/controllers/admin/registrations_controller.rb' "edited copy of a stock override IS flagged"
chk 'has human bundled_gem_require lib/watcher.rb'             "require of a bundled gem missing from the lock needs a human"
chk '[ "$(grep -o "\"line\":[0-9]*" "$WORK/scan.json" | head -1)" != "" ]' "findings carry line numbers"
csv_flagged=$($RUBY -rjson -e 'd=JSON.parse(File.read(ARGV[0])); puts d["human"].count{|f| f["detail"].to_s.include?("csv")}' "$WORK/scan.json")
chk '[ "$csv_flagged" = "0" ]' "require of a bundled gem that IS in the lock is not flagged"
chk '[ "$(count auto)" = "6" ]' "exactly the 6 auto-fix sites (3 enums, proxy, 2 config lines)"

echo "== scan is read-only"
before="$(cd "$O" && find . -type f -exec sha1sum {} + | sort)"
scan scan "$O" --gemfile-lock "$WORK/Gemfile.lock" >/dev/null
after="$(cd "$O" && find . -type f -exec sha1sum {} + | sort)"
chk '[ "$before" = "$after" ]' "scan changes no file"

echo "== apply"
scan apply "$O" --gemfile-lock "$WORK/Gemfile.lock" > "$WORK/apply.json"; rc=$?
chk '[ $rc -eq 0 ]' "apply exits 0"
chk 'grep -q "enum :status, { pending: 0, paid: 1 }, prefix: true" "$O/app/models/order.rb"' "enum rewritten, _prefix -> prefix"
chk 'grep -q "enum :size, \[:small, :large\]" "$O/app/models/order.rb"' "array enum rewritten"
chk 'grep -q "enum :tier, {" "$O/app/models/order.rb" && grep -q "}, suffix: :tier" "$O/app/models/order.rb"' "multi-line enum rewritten, _suffix -> suffix"
chk 'grep -q "enum :kind, { a: 0, b: 1 }" "$O/app/models/order.rb"' "already-new enum left alone"
chk 'grep -q "enum color: { red: 0 }, shape:" "$O/app/models/both.rb"' "human-fix enum NOT touched"
chk 'grep -q "class Proxy < BasicObject" "$O/lib/proxy.rb"' "ProxyObject -> BasicObject"
chk '! grep -q "read_encrypted_secrets\|warn_on_records_fetched" "$O/config/environments/development.rb"' "removed config lines deleted"
chk 'grep -q "config.eager_load = false" "$O/config/environments/development.rb"' "other config lines kept"
chk 'grep -q "Rails.application.secrets" "$O/config/initializers/keys.rb"' "secrets line NOT touched"

echo "== apply is idempotent"
scan scan "$O" --gemfile-lock "$WORK/Gemfile.lock" > "$WORK/scan.json"
chk '[ "$(count auto)" = "0" ]' "rescan after apply finds no auto-fixes"
snap="$(cd "$O" && find . -type f -exec sha1sum {} + | sort)"
scan apply "$O" --gemfile-lock "$WORK/Gemfile.lock" >/dev/null
chk '[ "$snap" = "$(cd "$O" && find . -type f -exec sha1sum {} + | sort)" ]' "second apply changes nothing"

echo
if [ "$fails" -eq 0 ]; then echo "ALL PASS"; exit 0; fi
echo "$fails FAILED"; exit 1
