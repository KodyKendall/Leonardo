# This migration comes from llama_bot_rails (originally 20260316161403)
class CreateLlamaBotRailsDirectMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_direct_messages do |t|
      t.references :conversation, null: false, foreign_key: { to_table: :llama_bot_rails_conversations }
      t.integer :sender_id, null: false
      t.text :body, null: false
      t.datetime :edited_at

      t.timestamps
    end

    add_index :llama_bot_rails_direct_messages, :sender_id
    add_index :llama_bot_rails_direct_messages, :created_at
    add_index :llama_bot_rails_direct_messages, [:conversation_id, :created_at], name: 'idx_dm_conversation_timeline'
  end
end
