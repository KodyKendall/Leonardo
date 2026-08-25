class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend  # Pagination - provides pagy() method for controllers
  
  # Do NOT put this back to Rails' `:modern` default (Safari 17.2+ / Chrome 120+).
  # `:modern` returns a hard HTTP 406 "browser not supported" page on EVERY route,
  # sign-in included, so an older phone gets no app at all. Our users are small
  # businesses on whatever phone they own: a 2026-08-23 sweep of 129 running boxes
  # found 89 of them unreachable from Samsung Internet 23 and iOS Safari 16.6.
  # Browsers not named in this hash are allowed through, so this widens rather than
  # enumerates. Guarded by spec/requests/allow_browser_spec.rb. SupportIncident #344.
  allow_browser versions: { safari: 15, chrome: 96, firefox: 95, opera: 82, ie: false }

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

  # `prepend: true` is load-bearing, do not drop it (SupportIncident #187 — a customer
  # was locked out of his own app for hours with the CORRECT password).
  # Without it, verify_authenticity_token runs LAST. On POST /users/sign_in, warden
  # authenticates from the form params inside an earlier before_action
  # (`touch_last_seen` calls `user_signed_in?`), and Devise's
  # `clean_up_csrf_token_on_authentication` deletes session[:_csrf_token] right then.
  # Verification afterwards finds no token and fails on a perfectly valid request.
  # The bug is invisible at build time because magic-link GET /auto_login/:id skips CSRF.
  protect_from_forgery with: :exception, prepend: true, unless: :api_request?

  before_action :allow_iframe_requests
  before_action :set_context
  before_action :touch_last_seen

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

  # Trackable's last_sign_in_at goes stale for users who stay signed in for weeks;
  # last_seen_at measures actual usage. Throttled to one write per 15 minutes.
  def touch_last_seen
    return unless user_signed_in?
    return if current_user.last_seen_at&.after?(15.minutes.ago)
    current_user.update_column(:last_seen_at, Time.current)
  end

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
