require 'rails_helper'

# Contract for the agent-facing User API consumed by the user_api_agent LangGraph agent
# through the llamapress_api layer. The deterministic, security-relevant behavior is:
#   - a valid LlamaBot agent token authenticates (the allow-listed actions sign the user in)
#   - no token (and no Devise session) cannot read users
#   - secrets are never serialized
RSpec.describe "Api::Users (agent API)", type: :request do
  def llama_bot_headers(user)
    token = Rails.application.message_verifier(:llamabot_ws).generate(
      { session_id: SecureRandom.uuid, user_id: user.id },
      expires_in: 30.minutes
    )
    { "Authorization" => "LlamaBot #{token}" }
  end

  let!(:alice) { create(:user, email: "alice@example.com", name: "Alice") }
  let!(:bob)   { create(:user, email: "bob@example.com", name: "Bob") }

  describe "GET /api/users" do
    it "does not let an unauthenticated request read users" do
      get "/api/users"
      expect(response).not_to have_http_status(:ok)
    end

    it "returns users as JSON for a valid LlamaBot agent token" do
      get "/api/users", headers: llama_bot_headers(alice)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.map { |u| u["email"] }).to include("alice@example.com", "bob@example.com")
      expect(body.first.keys).to include("id", "email", "name")
      expect(response.body).not_to include("encrypted_password")
      expect(response.body).not_to include("api_token")
    end

    it "filters by the q parameter" do
      get "/api/users", params: { q: "alice" }, headers: llama_bot_headers(alice)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).map { |u| u["email"] }).to eq(["alice@example.com"])
    end
  end

  describe "GET /api/users/:id" do
    it "returns a single user for a valid token" do
      get "/api/users/#{bob.id}", headers: llama_bot_headers(alice)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["email"]).to eq("bob@example.com")
    end

    it "returns 404 JSON for a missing user" do
      get "/api/users/0", headers: llama_bot_headers(alice)

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to include("error")
    end
  end
end
