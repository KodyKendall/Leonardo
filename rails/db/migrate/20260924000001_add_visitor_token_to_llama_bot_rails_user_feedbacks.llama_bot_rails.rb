# This migration comes from llama_bot_rails (originally 20260924000001)
class AddVisitorTokenToLlamaBotRailsUserFeedbacks < ActiveRecord::Migration[7.0]
  # Feedback Replay: the first-party `llama_visitor` cookie of the browser that sent the
  # note, so notes from one visitor can be grouped on an app nobody signs in to. Only a
  # value shaped like a token the engine issued is ever stored.
  def change
    add_column :llama_bot_rails_user_feedbacks, :visitor_token, :string
    add_index :llama_bot_rails_user_feedbacks, :visitor_token
  end
end
