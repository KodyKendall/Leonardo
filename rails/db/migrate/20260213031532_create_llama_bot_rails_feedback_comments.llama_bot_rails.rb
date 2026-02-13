# This migration comes from llama_bot_rails (originally 20260212000010)
class CreateLlamaBotRailsFeedbackComments < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_feedback_comments do |t|
      t.references :commentable, polymorphic: true, null: false
      t.text :body, null: false
      t.integer :user_id
      t.string :author_name
      t.boolean :is_admin_response, default: false

      t.timestamps
    end

    add_index :llama_bot_rails_feedback_comments, :user_id
    add_index :llama_bot_rails_feedback_comments, [:commentable_type, :commentable_id],
              name: 'index_feedback_comments_on_commentable'
  end
end
