# This migration comes from llama_bot_rails (originally 20260705000001)
# Unified Login Phase 3 — Piece 3.
#
# Adds the stable identity key the gem's default guid_user_resolver
# (lib/llama_bot_rails.rb) looks users up by, so GET /llamapress_auth/consume can
# sign a user into the host app's Devise session from a one-time mothership grant.
#
# Nullable, no backfill: existing box users stay NULL and are adopted later via
# the one-time email-link path (design §7); after linking, the GUID always wins
# over email. The PARTIAL unique index lets many NULLs coexist while keeping each
# real guid unique — mirroring the LlamaBot Alembic index shipped in Phase 2 and
# the mothership's users.public_id (which IS the guid). NEVER key a user by email.
class AddLlamapressUserGuidToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :llamapress_user_guid, :string
    add_index  :users, :llamapress_user_guid, unique: true,
               where: "llamapress_user_guid IS NOT NULL"
  end
end
