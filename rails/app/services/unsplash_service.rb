# app/services/unsplash_service.rb
require 'net/http'
require 'json'
require 'uri'

class UnsplashService
  UNSPLASH_API_URL = "https://api.unsplash.com"

  def initialize(api_key: ENV["UNSPLASH_ACCESS_KEY"], app_name: ENV["UNSPLASH_APP_NAME"] || "leonardo_rails_app")
    @api_key = api_key
    @app_name = app_name
  end

  # Search for photos
  # Example: UnsplashService.new.search("mountains", count: 1)
  def search(query, count: 3, orientation: nil, size: 'regular')
    params = {
      query: query,
      per_page: count
    }
    params[:orientation] = orientation if orientation

    uri = URI("#{UNSPLASH_API_URL}/search/photos")
    uri.query = URI.encode_www_form(params)

    response = get(uri)
    return response if response[:error]

    data = response[:data]
    (data["results"] || []).map { |photo| map_photo(photo, size) }
  rescue => e
    { error: "Unsplash search failed: #{e.message}" }
  end

  # Get a single photo by ID
  # Example: UnsplashService.new.get_by_id("abc123")
  def get_by_id(photo_id, size: 'regular')
    uri = URI("#{UNSPLASH_API_URL}/photos/#{photo_id}")
    
    response = get(uri)
    return response if response[:error]

    map_photo(response[:data], size)
  rescue => e
    { error: "Unsplash get_by_id failed: #{e.message}" }
  end

  private

  def get(uri)
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Client-ID #{@api_key}"
    req["Accept-Version"] = "v1"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

    if res.is_a?(Net::HTTPSuccess)
      { data: JSON.parse(res.body) }
    else
      { error: "Unsplash API error: #{res.code} #{res.body}" }
    end
  end

  def map_photo(photo, size)
    photographer = photo.dig("user", "name")
    photographer_url = "#{photo.dig("user", "links", "html")}?utm_source=#{@app_name}&utm_medium=referral"
    unsplash_url = "https://unsplash.com/?utm_source=#{@app_name}&utm_medium=referral"

    {
      url: photo.dig("urls", size),
      alt_description: photo["alt_description"],
      photographer: photographer,
      photographer_url: photographer_url,
      html_attribution: "Photo by <a href='#{photographer_url}'>#{photographer}</a> on <a href='#{unsplash_url}'>Unsplash</a>"
    }
  end
end
