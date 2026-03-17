# This migration comes from llama_bot_rails (originally 20260316161402)
class CreateLlamaBotRailsConversationParticipants < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_conversation_participants do |t|
      t.references :conversation, null: false, foreign_key: { to_table: :llama_bot_rails_conversations }
      t.integer :user_id, null: false
      t.datetime :last_read_at
      t.boolean :muted, default: false
      t.datetime :joined_at, null: false

      t.timestamps
    end

    add_index :llama_bot_rails_conversation_participants, :user_id
    add_index :llama_bot_rails_conversation_participants, [:conversation_id, :user_id], unique: true, name: 'idx_conv_participants_unique'
    add_index :llama_bot_rails_conversation_participants, :last_read_at
  end
end
