# This migration comes from llama_bot_rails (originally 20260212000006)
class CreateLlamaBotRailsUserFeedbacks < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_user_feedbacks do |t|
      t.string :title, null: false
      t.text :description
      t.string :feedback_type, null: false, default: 'general'
      t.string :status, null: false, default: 'open'
      t.integer :priority, default: 0
      t.integer :user_id, null: false
      t.string :user_email
      t.text :admin_notes
      t.string :resolution
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :llama_bot_rails_user_feedbacks, :user_id
    add_index :llama_bot_rails_user_feedbacks, :status
    add_index :llama_bot_rails_user_feedbacks, :feedback_type
    add_index :llama_bot_rails_user_feedbacks, :priority
    add_index :llama_bot_rails_user_feedbacks, :created_at
  end
end
