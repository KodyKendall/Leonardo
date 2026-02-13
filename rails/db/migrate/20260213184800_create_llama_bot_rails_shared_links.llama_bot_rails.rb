# This migration comes from llama_bot_rails (originally 20260213000001)
class CreateLlamaBotRailsSharedLinks < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_shared_links do |t|
      t.string :token, null: false
      t.bigint :attachment_id, null: false
      t.integer :view_count, default: 0
      t.datetime :expires_at
      t.integer :created_by_id

      t.timestamps
    end

    add_index :llama_bot_rails_shared_links, :token, unique: true
    add_index :llama_bot_rails_shared_links, :attachment_id

    # Foreign key to active_storage_attachments - auto-delete when attachment is purged
    add_foreign_key :llama_bot_rails_shared_links, :active_storage_attachments,
                    column: :attachment_id, on_delete: :cascade
  end
end
