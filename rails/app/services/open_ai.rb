# app/services/open_ai.rb
require 'net/http'
require 'json'
require 'uri'
require 'base64'
require 'tempfile'

class OpenAi
  OPENAI_API_URL = "https://api.openai.com/v1"

  def initialize(api_key: ENV["OPENAI_API_KEY"])
    @api_key = api_key
  end

  # === Generate Image ===
  # Example:
  #   OpenAI.new.generate_image("a purple llama", attach_to: user, attachment_name: :avatar)
  def generate_image(prompt, size: "1024x1024", attach_to: nil, attachment_name: nil)
    uri = URI("#{OPENAI_API_URL}/images/generations")
    req = Net::HTTP::Post.new(uri, headers)
    req.body = { model: "dall-e-3", prompt: prompt, size: size, response_format: "b64_json" }.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    raise "Image generation failed: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)

    data = JSON.parse(res.body)

    if (error = data["error"]) && error["message"]
      raise "OpenAI error: #{error["message"]}"
    end

    image_b64 = data.dig("data", 0, "b64_json")
    image_content = nil

    if image_b64 && !image_b64.empty?
      image_content = Base64.decode64(image_b64)
    else
      image_url = data.dig("data", 0, "url")
      raise "No image returned by OpenAI" unless image_url
      image_content = download_binary(image_url)
    end

    file = write_tempfile(image_content, "png")

    if attach_to && attachment_name
      attach_to.public_send(attachment_name).attach(io: file, filename: "openai.png", content_type: "image/png")
      return attach_to.public_send(attachment_name)
    end

    file
  end

  # === Generate Audio (Text-to-Speech) ===
  # Example:
  #   OpenAI.new.generate_audio("Hello world", attach_to: message, attachment_name: :voice_note)
  def generate_audio(text, voice: "alloy", format: "mp3", attach_to: nil, attachment_name: nil)
    uri = URI("#{OPENAI_API_URL}/audio/speech")
    req = Net::HTTP::Post.new(uri, headers("Content-Type" => "application/json"))
    req.body = {
      model: "gpt-4o-mini-tts",
      voice: voice,
      input: text,
      format: format
    }.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    raise "Audio generation failed: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)

    file = write_tempfile(res.body, format)

    if attach_to && attachment_name
      attach_to.public_send(attachment_name).attach(io: file, filename: "openai.#{format}", content_type: "audio/#{format}")
      return attach_to.public_send(attachment_name)
    end

    file
  end

  private

  def headers(extra = {})
    {
      "Authorization" => "Bearer #{@api_key}",
      "Content-Type" => "application/json"
    }.merge(extra)
  end

  def write_tempfile(content, ext)
    file = Tempfile.new(["openai", ".#{ext}"])
    file.binmode
    file.write(content)
    file.rewind
    file
  end

  def download_binary(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    raise "Image download failed: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)
    response.body
  end
end

# examples: 
# user = User.find(1)
# OpenAI.new.generate_image("a purple llama", attach_to: user, attachment_name: :avatar)

# message = Message.create!(body: "Hello world")
# OpenAI.new.generate_audio("This is your AI speaking", attach_to: message, attachment_name: :voice_note)

# file = OpenAI.new.generate_audio("Standalone test")
# FileUtils.mv(file.path, "speech.mp3")