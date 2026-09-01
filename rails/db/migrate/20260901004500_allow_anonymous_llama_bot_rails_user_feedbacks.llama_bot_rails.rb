# This migration comes from llama_bot_rails (originally 20260901000001)
class AllowAnonymousLlamaBotRailsUserFeedbacks < ActiveRecord::Migration[7.0]
  # Signed-out visitors can submit feedback when an app opts in
  # (config.llama_bot_rails.anonymous_feedback_enabled). Such a row has no user by
  # definition, so user_id has to be nullable. The model still validates its presence
  # for every app that has NOT opted in, so this loosens the database only.
  #
  # submitted_ip exists so a human can trace and ban an abusive source later. Note it is
  # weak evidence on a Leo box: Caddy overwrites X-Forwarded-For, so remote_ip there is
  # the LXD bridge address and many visitors can share one value.
  def change
    change_column_null :llama_bot_rails_user_feedbacks, :user_id, true
    add_column :llama_bot_rails_user_feedbacks, :submitted_ip, :string
  end
end
