# This migration comes from llama_bot_rails (originally 20261126000001)
class AddPageCommentAnchorsToLlamaBotRailsUserFeedbacks < ActiveRecord::Migration[7.0]
  # LP-57 page comments: a feedback row of type "page_comment" pinned to a quote on one
  # URL path. All nullable and additive; the element selector reuses the existing
  # selected_element_selector column. Rolling back drops only these columns, and the
  # page-comment rows stay behind as ordinary feedback.
  def change
    add_column :llama_bot_rails_user_feedbacks, :anchor_quote, :text
    add_column :llama_bot_rails_user_feedbacks, :anchor_prefix, :string, limit: 64
    add_column :llama_bot_rails_user_feedbacks, :anchor_suffix, :string, limit: 64
    add_column :llama_bot_rails_user_feedbacks, :anchor_label, :string
    add_column :llama_bot_rails_user_feedbacks, :page_path, :string
    add_column :llama_bot_rails_user_feedbacks, :anchor_state, :string, default: "attached"
    add_column :llama_bot_rails_user_feedbacks, :anchor_checked_at, :datetime
    add_index :llama_bot_rails_user_feedbacks, [:page_path, :feedback_type],
              name: "index_llama_bot_rails_user_feedbacks_on_page_comments"
  end
end
