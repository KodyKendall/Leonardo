class PublicController < ApplicationController
    skip_before_action :authenticate_user!
  
    # Root page of our application.
    # GET /
    def home
      # Fetch all pages from app/views/pages/ to list them as posts
      pages_dir = Rails.root.join("app/views/pages")
      @posts = Dir.glob(pages_dir.join("**/*.html.erb"))
                 .map { |f| f.sub(pages_dir.to_s, "").sub(".html.erb", "") }
                 .reject { |s| s.include?("/_") } # Exclude partials
                 .map { |s| s.starts_with?("/") ? s[1..-1] : s } # Remove leading slash
    end

    # Chat page of our application.
    # GET /chat
    def chat
    end
  end
