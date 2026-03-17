# This migration comes from llama_bot_rails (originally 20260316161401)
class CreateLlamaBotRailsConversations < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_conversations do |t|
      t.string :title
      t.string :conversation_type, null: false, default: 'direct'

      t.timestamps
    end

    add_index :llama_bot_rails_conversations, :conversation_type
    add_index :llama_bot_rails_conversations, :updated_at
  end
end
