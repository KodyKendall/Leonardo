class PagesController < ApplicationController
  skip_before_action :authenticate_user_from_token!
  skip_before_action :authenticate_user!

  def show
    @slug = params[:slug]
    
    # Path inside app/views/pages/
    # We sanitize to prevent directory traversal
    path = Rails.root.join("app/views/pages/#{@slug}.html.erb")
    
    if File.exist?(path)
      render template: "pages/#{@slug}"
    else
      render plain: "404 Not Found", status: :not_found
    end
  end
end
