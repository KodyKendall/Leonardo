module Api
  # Agent-facing JSON API for the "User Mode (API)" LangGraph agent (user_api_agent).
  #
  # Reachable by the LlamaBot agent via the `Authorization: LlamaBot <api_token>` header
  # because the actions below are allow-listed with `llama_bot_allow`. The gem's
  # LlamaBotRails::AgentAuth verifies the signed token, resolves its user_id, and signs
  # that user in for the request — so `current_user` works exactly as it would for a
  # browser (Devise) session. Both auth paths are accepted.
  #
  # This goes "through the app": results are whatever the app chooses to expose, not raw
  # ActiveRecord. Tighten `index`/`show` scoping here if users should only see a subset.
  class UsersController < ApplicationController
    # Opt this controller into the LlamaBot agent-auth mechanism. These are no-ops on
    # deployments where the gem's railtie already mixes them into ActionController::Base;
    # including them here makes the endpoint work regardless of that wiring.
    include LlamaBotRails::ControllerExtensions # provides `llama_bot_allow`
    include LlamaBotRails::AgentAuth            # makes `authenticate_user!` accept the agent token

    before_action :authenticate_user! # Devise session OR LlamaBot agent token (see AgentAuth)
    llama_bot_allow :index, :show, :create

    # CSRF. Needed once a non-GET action exists here (GETs are never checked).
    #
    # ApplicationController declares `protect_from_forgery with: :exception, unless:
    # :api_request?`, and its `api_request?` only recognises the `Bearer` scheme — not
    # the gem's `LlamaBot` scheme. So an agent POST raises InvalidAuthenticityToken.
    #
    # Do NOT "fix" this by skipping CSRF outright: this controller is reachable TWO
    # ways and they need opposite treatment.
    #   - A verified LlamaBot token can't be forged by a cross-origin page (no
    #     secret_key_base, and browsers can't set an Authorization header cross-origin
    #     without a CORS preflight). CSRF protects nothing there.
    #   - A Devise SESSION cookie is exactly what CSRF exists to protect: a malicious
    #     page could otherwise make a logged-in admin's browser POST here.
    # So: drop the inherited check, then re-add it for everything that isn't a
    # cryptographically verified agent request. `llama_bot_request?` (AgentAuth) returns
    # true only when the signature verifies, which is what makes this safe to key on.
    skip_before_action :verify_authenticity_token
    before_action :verify_authenticity_token,
                  unless: -> { llama_bot_request? || api_request? }

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "User not found" }, status: :not_found
    end

    # GET /api/users?q=<substring>
    def index
      users = User.all
      if params[:q].present?
        term = "%#{User.sanitize_sql_like(params[:q].to_s.strip)}%"
        users = users.where("email ILIKE :term OR name ILIKE :term", term: term)
      end
      render json: users.order(:email).limit(25).map { |u| user_json(u) }
    end

    # GET /api/users/:id
    def show
      render json: user_json(User.find(params[:id]))
    end

    # POST /api/users
    #
    # The first WRITE exposed to the agent, so read `user_params` before touching this.
    # `llama_bot_allow :create` only makes the action REACHABLE; it says nothing about
    # what the caller may set. Strong params are what stand between "the agent can add
    # a user" and "the agent can add an ADMIN user" — see below.
    def create
      user = User.new(user_params)
      # If/when this app adopts Pundit, `authorize user` belongs here: llama_bot_allow
      # gates reachability for agents, Pundit gates whether THIS user may create.
      # Right now any user who can reach the agent can create a (non-admin) user.
      if user.save
        render json: user_json(user), status: :created
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    # NOTE the omissions, both deliberate:
    #   :admin     — permitting it would let an agent-driven POST mint an admin, which
    #                is exactly the privilege escalation this whole design exists to
    #                prevent. The token proves WHO is asking; it can't stop a controller
    #                from handing out privileges it was told to hand out.
    #   :api_token — assigned by the model's before_create hook. It's a long-lived
    #                bearer credential for the account; never caller-settable.
    # Devise's :validatable requires email + password, so password is permitted (and
    # required in practice — a POST without one comes back 422 with the reason).
    def user_params
      params.require(:user).permit(:email, :name, :password)
    end

    def user_json(user)
      {
        id: user.id,
        email: user.email,
        name: user.name,
        admin: user.admin,
        created_at: user.created_at
      }
    end
  end
end
