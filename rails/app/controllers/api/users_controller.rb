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
    llama_bot_allow :index, :show

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

    private

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
