# This migration comes from llama_bot_rails (originally 20260316161404)
class CreateLlamaBotRailsNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_notifications do |t|
      t.integer :user_id, null: false
      t.integer :actor_id
      t.references :notifiable, polymorphic: true, null: false
      t.string :notification_type, null: false
      t.text :message
      t.datetime :read_at
      t.json :metadata

      t.timestamps
    end

    add_index :llama_bot_rails_notifications, :user_id
    add_index :llama_bot_rails_notifications, :actor_id
    add_index :llama_bot_rails_notifications, :notification_type
    add_index :llama_bot_rails_notifications, :read_at
    add_index :llama_bot_rails_notifications, [:user_id, :read_at], name: 'idx_notifications_user_unread'
    add_index :llama_bot_rails_notifications, [:notifiable_type, :notifiable_id], name: 'idx_notifications_notifiable'
  end
end
