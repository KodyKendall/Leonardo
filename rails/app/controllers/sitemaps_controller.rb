class SitemapsController < ApplicationController
  skip_before_action :authenticate_user_from_token!
  skip_before_action :authenticate_user!

  def index
    # Find all .html.erb files in app/views/pages/
    # We want to exclude partials (files starting with _)
    pages_dir = Rails.root.join("app/views/pages")
    
    # Check if the directory exists
    unless Dir.exist?(pages_dir)
      @urls = []
      return
    end

    @urls = Dir.glob(pages_dir.join("**/*.html.erb"))
              .map { |f| f.sub(pages_dir.to_s, "").sub(".html.erb", "") }
              .reject { |s| s.include?("/_") } # Exclude partials
              .map { |s| s.starts_with?("/") ? s[1..-1] : s } # Remove leading slash
    
    # Add root manually if it's not in pages
    @urls.unshift("") unless @urls.include?("")
  end
end
