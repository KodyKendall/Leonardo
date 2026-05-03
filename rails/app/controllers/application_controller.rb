class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend  # Pagination - provides pagy() method for controllers
  
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # AUTHENTICATION IS DISABLED BY DEFAULT FOR NEW PROJECTS.
  #
  # Leonardo: when the user asks to enable authentication (e.g. "require login",
  # "lock this down", "add auth"), uncomment the two `before_action` lines below.
  # - `authenticate_user_from_token!` handles API requests via Bearer token / `api_token` param.
  # - `authenticate_user!` (provided by Devise) handles browser/session requests.
  # If only certain controllers should require auth, leave these commented and add
  # the `before_action` to those controllers instead, or use `skip_before_action`
  # in controllers that should remain public (e.g. HomeController, Devise controllers).
  #
  # IMPORTANT: any `skip_before_action :authenticate_user!` in child controllers
  # MUST use `raise: false` so they remain safe while auth is disabled, e.g.:
  #   skip_before_action :authenticate_user!, raise: false
  # Without `raise: false`, Rails raises ArgumentError ("callback ... has not been
  # defined") at boot when the callback isn't registered.
  #
  # before_action :authenticate_user_from_token!
  # before_action :authenticate_user!

  before_action :allow_iframe_requests
  before_action :set_context
  protect_from_forgery with: :exception, unless: :api_request?

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

  def authenticate_user_from_token!
    return unless api_request?

    token = request.headers['Authorization']&.match(/^Bearer\s+(.+)$/)&.captures&.first ||
            params['api_token']

    if token.present?
      user = User.find_by(api_token: token)
      if user
        sign_in(user, store: false)
        return
      end
    end

    render json: { error: 'Invalid API token' }, status: :unauthorized
  end

  def api_request?
    request.headers['Authorization']&.start_with?('Bearer ') ||
    params['api_token'].present?
  end

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
