# app/controllers/webhooks_controller.rb
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def recall
    # Read body ONCE and store it
    payload_body = request.body.read

    # 1. Verify the request came from Recall
    begin
      RecallAi.new.verify_webhook!(payload_body, request.headers)
    rescue => e
      Rails.logger.error("Recall webhook verification failed: #{e.message}")
      render json: { error: "Unverified" }, status: :unauthorized
      return
    end

    # 2. Process the event
    event = JSON.parse(payload_body)

    case event["event"]
    when "bot.status_change"
      handle_status_change(event["data"])
    end

    head :ok
  end

  private

  def handle_status_change(data)
    bot_id = data["bot_id"] || data.dig("bot", "id")
    status_code = data.dig("status", "code") || data["status_code"]

    Rails.logger.info("Bot #{bot_id} status changed to: #{status_code}")

    if status_code == "done" && bot_id.present?
      Rails.logger.info("Meeting Finished! Saving conversation...")

      # Save the transcript in the background to avoid blocking the webhook response
      Thread.new do
        begin
          file_path = RecallAi.new.save_conversation(bot_id)
          Rails.logger.info("Conversation saved to: #{file_path}")
        rescue => e
          Rails.logger.error("Failed to save conversation: #{e.message}")
        end
      end
    end
  end
end
