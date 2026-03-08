# frozen_string_literal: true

# Rack::Attack configuration for rate limiting and request throttling
# https://github.com/rack/rack-attack

class Rack::Attack
  ### Configure Cache ###
  # Use Rails cache by default. For production, consider Redis:
  # Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV["REDIS_URL"])

  ### Throttle Spammy Clients ###
  # Throttle all requests by IP (60 requests per minute)
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets", "/packs")
  end

  ### Prevent Brute-Force Login Attacks ###
  # Throttle POST requests to /users/sign_in by IP address
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle POST requests to /users/sign_in by email parameter
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Normalize email to prevent circumvention
      req.params.dig("user", "email").to_s.downcase.gsub(/\s+/, "").presence
    end
  end

  ### Prevent Password Reset Flooding ###
  throttle("password_resets/ip", limit: 5, period: 1.minute) do |req|
    if req.path == "/users/password" && req.post?
      req.ip
    end
  end

  ### Custom Blocklist ###
  # Block suspicious requests (SQL injection attempts, etc.)
  blocklist("fail2ban/sql_injection") do |req|
    Rack::Attack::Fail2Ban.filter("sql_injection-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      CGI.unescape(req.query_string).match?(/(\%27)|(\')|(\-\-)|(\%23)|(#)/i)
    end
  end

  ### Safelist ###
  # Always allow requests from localhost in development
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  ### Custom Response ###
  # Return 429 Too Many Requests with a custom message
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    headers = {
      "Content-Type" => "text/plain",
      "Retry-After" => (match_data[:period] - (now % match_data[:period])).to_s
    }

    [429, headers, ["Rate limit exceeded. Please retry later.\n"]]
  end

  self.blocklisted_responder = lambda do |request|
    [403, { "Content-Type" => "text/plain" }, ["Forbidden\n"]]
  end
end

# Enable Rack::Attack in the middleware stack
Rails.application.config.middleware.use Rack::Attack
