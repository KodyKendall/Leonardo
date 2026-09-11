require 'rails_helper'

# Regression for the 2026-09-07 sign-in failure ("Can't verify CSRF token authenticity"
# on POST /users/sign_in), seen on leo-rozeze at 21:05Z minutes before a customer
# kickoff call.
#
# A browser with NO session cookie opens a Leo app inside LlamaBot. The chat pane
# requests /llama_bot/conversations (-> /llama_bot/sign_in) at the same moment the app
# iframe requests / (-> /users/sign_in). Both responses mint a brand-new
# _rails_basic_session cookie and the browser keeps whichever lands last, so the sign-in
# form's authenticity_token is bound to the session the browser just dropped. The POST
# then raised InvalidAuthenticityToken into the Leonardo error page. A reload fixes it,
# which is why it looked random.
#
# Two layers, both under test here:
#   1. GET /users/sign_in/token returns a token for the cookie the browser holds NOW;
#      the form fetches it on submit and swaps it in.
#   2. A stale token that still gets through re-renders the form with a fresh token and
#      a plain message, 422, instead of raising.
#
# See Users::SessionsController.
RSpec.describe "Sign-in CSRF token race", type: :request do
  let!(:user) do
    User.create!(email: "race@example.com", password: "password123",
                 password_confirmation: "password123")
  end

  # rails_helper stubs verify_authenticity_token for EVERY request spec
  # (and_return(true)), so the real check never runs there — which is why
  # csrf_ordering_spec.rb never exercised it. This spec IS about the real check.
  before do
    allow_any_instance_of(ActionController::Base).to receive(:verify_authenticity_token).and_call_original
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  def form_token(body)
    body[/name="authenticity_token" value="([^"]+)"/, 1]
  end

  def credentials
    { user: { email: user.email, password: "password123" } }
  end

  it "actually verifies (a garbage token is rejected)" do
    # Guards the guard: if the rails_helper stub ever leaks back in, every other
    # expectation here would pass for the wrong reason.
    get new_user_session_path
    post user_session_path, params: credentials.merge(authenticity_token: "garbage")

    expect(response).to have_http_status(:unprocessable_entity)
    expect(session["warden.user.user.key"]).to be_nil
  end

  it "re-renders the form with a fresh token instead of crashing when the cookie changed" do
    get new_user_session_path
    stale_token = form_token(response.body)
    expect(stale_token).to be_present

    reset!                          # the browser now holds a different session cookie
    get new_user_session_path       # (the other page's response won the cookie race)

    post user_session_path, params: credentials.merge(authenticity_token: stale_token)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("press Sign in again")
    expect(response.body).to include('value="race@example.com"')

    # An unverified POST must never sign anyone in. Devise authenticates lazily from the
    # posted email/password the moment the layout asks for current_user (the SI#187
    # mechanism), which would quietly log the user in off a request we just rejected.
    expect(session["warden.user.user.key"]).to be_nil

    fresh_token = form_token(response.body)
    expect(fresh_token).to be_present
    expect(fresh_token).not_to eq(stale_token)

    post user_session_path, params: credentials.merge(authenticity_token: fresh_token)
    expect(response).to have_http_status(:redirect)
    expect(session["warden.user.user.key"]).to be_present
  end

  it "serves a token for the current cookie that the sign-in POST accepts" do
    get new_user_session_path
    reset!
    get new_user_session_path

    get user_sign_in_token_path, headers: { "Accept" => "application/json" }
    expect(response).to have_http_status(:ok)
    token = response.parsed_body["token"]
    expect(token).to be_present

    post user_session_path, params: credentials.merge(authenticity_token: token)
    expect(response).to have_http_status(:redirect)
    expect(session["warden.user.user.key"]).to be_present
  end

  it "does not require a signed-in user to fetch a token" do
    # The whole point is that it runs before anyone is signed in. A stray
    # authenticate_user! here would make the fix a redirect loop.
    get user_sign_in_token_path, headers: { "Accept" => "application/json" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["token"]).to be_present
  end

  it "never lets the token response be cached" do
    # A cached token is a token for somebody else's cookie — the bug again, but sticky.
    get user_sign_in_token_path, headers: { "Accept" => "application/json" }

    expect(response.headers["Cache-Control"]).to include("no-store")
  end
end
