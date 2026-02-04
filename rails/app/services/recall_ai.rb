# app/services/recall_ai.rb
require 'net/http'
require 'json'
require 'uri'
require 'openssl'

class RecallAi
  # NOTE: If you are hosted in EU or specialized regions,
  # update this to "https://eu-central-1.recall.ai/api/v1" etc.
  RECALL_API_URL = "https://us-west-2.recall.ai/api/v1"

  def initialize(api_key: ENV["RECALL_API_KEY"], webhook_secret: ENV["RECALL_WEBHOOK_SECRET"])
    @api_key = api_key
    @webhook_secret = webhook_secret
  end

  # === Join Meeting ===
  # Triggers a Recall.ai bot to join a specific meeting URL.
  #
  # Example (with real-time transcription enabled by default):
  #   RecallAi.new.join_meeting("https://zoom.us/j/123456789", bot_name: "Notetaker Bot")
  #
  # Example (disable transcription):
  #   RecallAi.new.join_meeting("https://zoom.us/j/123456789", transcribe: false)
  #
  # Example (prioritize accuracy over low latency):
  #   RecallAi.new.join_meeting("https://zoom.us/j/123456789", transcription_mode: "prioritize_accuracy")
  #
  # Returns the parsed JSON response containing the bot ID and status.
  def join_meeting(meeting_url, bot_name: "Recall Bot", transcribe: true, transcription_mode: "prioritize_low_latency")
    uri = URI("#{RECALL_API_URL}/bot")
    req = Net::HTTP::Post.new(uri, headers)

    payload = {
      meeting_url: meeting_url,
      bot_name: bot_name
    }

    # Enable transcription by default using Recall.ai's streaming provider
    # Uses recording_config.transcript structure (new API format)
    if transcribe
      payload[:recording_config] = {
        transcript: {
          provider: {
            recallai_streaming: {
              mode: transcription_mode,  # "prioritize_low_latency" or "prioritize_accuracy"
              language_code: "en"        # Required for low latency mode
            }
          }
        }
      }
    end

    req.body = payload.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

    unless res.is_a?(Net::HTTPSuccess)
      raise "Recall.ai Connection Failed: #{res.code} #{res.body}"
    end

    data = JSON.parse(res.body)

    if data["status"] && data["status"] == "fatal"
       raise "Recall.ai Bot Error: #{data['status_changes']}"
    end

    data
  end

  # === Get Bot Status ===
  # Useful for polling the bot to see if it successfully connected or left.
  #
  # Example:
  #   RecallAi.new.get_bot("bot-id-uuid")
  def get_bot(bot_id)
    uri = URI("#{RECALL_API_URL}/bot/#{bot_id}")
    req = Net::HTTP::Get.new(uri, headers)

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

    unless res.is_a?(Net::HTTPSuccess)
      raise "Recall.ai Fetch Failed: #{res.code} #{res.body}"
    end

    JSON.parse(res.body)
  end

  # === Get Transcript ===
  # Fetches the transcript for a completed bot session.
  # Uses the new v2 endpoint: /bot/{bot_id}/recording/{recording_id}/transcript
  #
  # Example:
  #   RecallAi.new.get_transcript("bot-id-uuid")
  #
  # Returns array of transcript segments with speaker, text, timestamps
  def get_transcript(bot_id)
    bot = get_bot(bot_id)
    recording_id = bot.dig("recordings", 0, "id")

    raise "No recording found for bot #{bot_id}" unless recording_id

    uri = URI("#{RECALL_API_URL}/bot/#{bot_id}/recording/#{recording_id}/transcript")
    req = Net::HTTP::Get.new(uri, headers)

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

    unless res.is_a?(Net::HTTPSuccess)
      raise "Recall.ai Transcript Fetch Failed: #{res.code} #{res.body}"
    end

    JSON.parse(res.body)
  end

  # === Get Recording URL ===
  # Returns the video/audio recording URL from a completed bot session.
  #
  # Example:
  #   url = RecallAi.new.get_recording_url("bot-id-uuid")
  #
  # Returns the video_url string (mp4), or nil if not ready
  def get_recording_url(bot_id)
    bot = get_bot(bot_id)
    bot.dig("recordings", 0, "media_shortcuts", "video_mixed", "data", "download_url")
  end

  # === Get Current Status ===
  # Returns the latest status code from status_changes array.
  #
  # Example:
  #   RecallAi.new.current_status("bot-id-uuid")
  #   # => "done"
  def current_status(bot_id)
    bot = get_bot(bot_id)
    bot["status_changes"]&.last&.dig("code")
  end

  # === Check if Recording is Ready ===
  # Helper to check if the bot has finished and recording is available.
  #
  # Example:
  #   RecallAi.new.recording_ready?("bot-id-uuid")
  def recording_ready?(bot_id)
    bot = get_bot(bot_id)
    status = bot["status_changes"]&.last&.dig("code")
    video_url = bot.dig("recordings", 0, "media_shortcuts", "video_mixed", "data", "download_url")
    status == "done" && video_url.present?
  end

  # === Save Conversation ===
  # Saves the transcript and meeting metadata to a text file in the conversations folder.
  #
  # Example:
  #   RecallAi.new.save_conversation("bot-id-uuid")
  #   # => "/path/to/rails/conversations/2026-02-04_bot-id-uuid.txt"
  #
  # Returns the file path of the saved conversation
  def save_conversation(bot_id)
    bot = get_bot(bot_id)

    # Get meeting info
    meeting_url = bot.dig("meeting_url", "meeting_id") || "unknown"
    platform = bot.dig("meeting_url", "platform") || "unknown"
    bot_name = bot["bot_name"] || "unknown"
    join_at = bot["join_at"]

    # Get transcript if available
    transcript_text = ""
    begin
      transcript = get_transcript(bot_id)
      if transcript.is_a?(Array)
        transcript_text = format_transcript(transcript)
      elsif transcript.is_a?(Hash) && transcript["results"]
        transcript_text = format_transcript(transcript["results"])
      else
        transcript_text = "[Transcript format unknown]\n#{transcript.to_json}"
      end
    rescue => e
      transcript_text = "[Transcript not available: #{e.message}]"
    end

    # Get video URL
    video_url = get_recording_url(bot_id) rescue "[Video URL not available]"

    # Build the conversation file content
    timestamp = Time.parse(join_at).strftime("%Y-%m-%d_%H-%M-%S") rescue Time.now.strftime("%Y-%m-%d_%H-%M-%S")
    filename = "#{timestamp}_#{bot_id}.txt"

    content = <<~CONVERSATION
      ================================================================================
      MEETING TRANSCRIPT
      ================================================================================

      Bot ID:       #{bot_id}
      Platform:     #{platform}
      Meeting ID:   #{meeting_url}
      Bot Name:     #{bot_name}
      Started At:   #{join_at}
      Saved At:     #{Time.now.iso8601}

      Video URL:
      #{video_url}

      ================================================================================
      TRANSCRIPT
      ================================================================================

      #{transcript_text}

      ================================================================================
      END OF TRANSCRIPT
      ================================================================================
    CONVERSATION

    # Save to conversations folder
    conversations_dir = Rails.root.join("conversations")
    FileUtils.mkdir_p(conversations_dir)

    file_path = conversations_dir.join(filename)
    File.write(file_path, content)

    Rails.logger.info("Saved conversation to #{file_path}")
    file_path.to_s
  end

  # === Verify Incoming Webhook ===
  # Call this in your controller when Recall sends you data.
  #
  # Args:
  #   payload_body: The raw string body of the request (request.body.read)
  #   headers: The request headers object
  #
  # Returns true if valid, raises error if invalid
  def verify_webhook!(payload_body, headers)
    timestamp = headers['x-recall-signature-timestamp'] || headers['webhook-timestamp']
    signature = headers['x-recall-signature'] || headers['webhook-signature']

    raise "Missing Webhook Headers" unless timestamp && signature

    signed_content = "#{timestamp}.#{payload_body}"

    expected_signature = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha256'),
      @webhook_secret,
      signed_content
    )

    match = signature.split(' ').any? do |sig_part|
      version, hash = sig_part.split(',')
      version == 'v1' && Rack::Utils.secure_compare(hash, expected_signature)
    end

    raise "Invalid Webhook Signature" unless match

    true
  end

  private

  def headers
    {
      "Authorization" => "Token #{@api_key}",
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end

  # Format transcript array into readable text
  def format_transcript(transcript_items)
    return "[Empty transcript]" if transcript_items.nil? || transcript_items.empty?

    transcript_items.map do |item|
      speaker = item["speaker"] || item["participant_name"] || "Unknown"
      text = item["text"] || item["words"]&.map { |w| w["text"] }&.join(" ") || ""
      timestamp = item["start_time"] || item["timestamp"] || ""

      if timestamp.present?
        "[#{format_time(timestamp)}] #{speaker}: #{text}"
      else
        "#{speaker}: #{text}"
      end
    end.join("\n\n")
  end

  # Convert seconds to readable time format
  def format_time(seconds)
    return seconds.to_s unless seconds.is_a?(Numeric)

    total_seconds = seconds.to_i
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    secs = total_seconds % 60

    if hours > 0
      format("%02d:%02d:%02d", hours, minutes, secs)
    else
      format("%02d:%02d", minutes, secs)
    end
  end
end


# client = RecallAi.new
# response = client.join_meeting("https://us02web.zoom.us/j/2674940883", bot_name: "Leonardo")
# bot_id = response["id"]
# puts "Bot ID: #{bot_id}"
