# This migration comes from llama_bot_rails (originally 20260212000007)
class CreateLlamaBotRailsUserRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_user_requests do |t|
      t.string :title, null: false
      t.text :description
      t.string :request_type, null: false, default: 'feature'
      t.string :status, null: false, default: 'submitted'
      t.integer :priority, default: 0
      t.integer :user_id, null: false
      t.string :user_email
      t.text :admin_notes
      t.text :response
      t.datetime :responded_at
      t.integer :votes_count, default: 0

      t.timestamps
    end

    add_index :llama_bot_rails_user_requests, :user_id
    add_index :llama_bot_rails_user_requests, :status
    add_index :llama_bot_rails_user_requests, :request_type
    add_index :llama_bot_rails_user_requests, :priority
    add_index :llama_bot_rails_user_requests, :votes_count
  end
end
