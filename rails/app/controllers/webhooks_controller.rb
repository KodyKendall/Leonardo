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
    if data["status"]["code"] == "done"
      Rails.logger.info("Meeting Finished! Video URL: #{data['video_url']}")
    end
  end
end
