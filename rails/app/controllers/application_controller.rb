class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :allow_iframe_requests
  before_action :set_context

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end

  def set_context
    @request_path = request.path
    @view_path = resolve_view_path #this is used for LlamaBot to know what file to write code changes to.
    
    # Prevent caching to ensure fresh request_path and view_path on every request
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
  end

  def stop_impersonating
    if session[:admin_id]
      admin = User.find(session.delete(:admin_id))
      sign_in(admin)
      redirect_to admin_root_path, notice: "Stopped impersonation"
    else
      redirect_to root_path
    end
  end

  private

  def resolve_view_path
    route = Rails.application.routes.recognize_path(request.path, method: request.method)
    controller = route[:controller]
    action = route[:action]

    # Check if there's a specific route helper for this path
    route_helper = Rails.application.routes.named_routes.helper_names.find do |helper|
      path = send("#{helper}_path") rescue nil
      path == request.path
    end

    if route_helper
      # If a route helper is found, use it to determine the view
      controller, action = route_helper.to_s.sub(/_path$/, '').split('_', 2)
    end

    "app/views/#{controller}/#{action}.html.erb"
  rescue ActionController::RoutingError
    nil
  end


end
