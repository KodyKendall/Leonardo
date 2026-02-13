# This migration comes from llama_bot_rails (originally 20260212000011)
class AddParentIdToFeedbackComments < ActiveRecord::Migration[7.2]
  def change
    add_column :llama_bot_rails_feedback_comments, :parent_id, :bigint
    add_index :llama_bot_rails_feedback_comments, :parent_id
    add_foreign_key :llama_bot_rails_feedback_comments, :llama_bot_rails_feedback_comments, column: :parent_id, on_delete: :cascade
  end
end
