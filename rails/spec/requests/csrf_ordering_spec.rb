require 'rails_helper'

# Regression for mothership SupportIncident #187 (leo-redo: customer locked out of his
# own app for hours with the CORRECT password) and the same fingerprint in SI#143.
#
# ApplicationController declared `protect_from_forgery` AFTER its before_actions and
# without `prepend: true`, so `verify_authenticity_token` ran LAST. On POST
# /users/sign_in, warden authenticates from the form params inside an earlier
# before_action (`touch_last_seen` calls `user_signed_in?`), and Devise's
# `clean_up_csrf_token_on_authentication` (default ON) deletes `session[:_csrf_token]`
# at that moment. Verification then finds no token and fails — with a valid token that
# the browser had just been served.
#
# The agent never sees it at build time because the magic-link `GET /auto_login/:id`
# bypasses CSRF entirely.
RSpec.describe "CSRF verification ordering", type: :request do
  describe "ApplicationController callback order" do
    it "verifies the authenticity token before any other before_action runs" do
      callbacks = ApplicationController._process_action_callbacks
                                      .select { |cb| cb.kind == :before }
                                      .map { |cb| cb.filter.to_s }

      verify_index = callbacks.index("verify_authenticity_token")
      expect(verify_index).not_to be_nil,
        "ApplicationController does not install verify_authenticity_token at all"

      # `touch_last_seen` triggers warden, which is what clears the CSRF token.
      offenders = callbacks.each_with_index.select do |name, index|
        index < verify_index && name != "verify_authenticity_token"
      end

      expect(offenders).to be_empty,
        "these before_actions run BEFORE verify_authenticity_token and can clear the " \
        "session CSRF token first: #{offenders.map(&:first).inspect}. " \
        "Declare protect_from_forgery with prepend: true."
    end
  end

  describe "password sign-in with a valid CSRF token", type: :request do
    let!(:user) do
      User.create!(
        email: "csrf-order@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
    end

    around do |example|
      # This is the whole point — exercise the real forgery check.
      original = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
      ActionController::Base.allow_forgery_protection = original
    end

    it "signs the user in and keeps the session" do
      get new_user_session_path
      expect(response).to have_http_status(:ok)

      token = css_csrf_token(response.body)
      expect(token).to be_present, "sign-in form served no authenticity_token"

      post user_session_path, params: {
        authenticity_token: token,
        user: { email: user.email, password: "password123" }
      }

      expect(response).to have_http_status(:redirect)

      # SI#187's log fingerprint: the POST returns 303 with NO Set-Cookie, because
      # `:null_session` discarded the freshly signed-in session after verification
      # failed. `sign_in_count` still increments, which is what made it look like the
      # password was being rejected when it wasn't.
      expect(user.reload.sign_in_count).to be >= 1,
        "warden never authenticated the credentials"
      expect(session["warden.user.user.key"]).to be_present,
        "signed in with the correct password but the session was discarded — the CSRF " \
        "token was cleared by warden before verification ran (SI#187 login loop)"

      follow_redirect!
      expect(response).not_to have_http_status(:unauthorized)
    end

    def css_csrf_token(body)
      match = body.match(/name="authenticity_token"\s+value="([^"]+)"/) ||
              body.match(/name="csrf-token"\s+content="([^"]+)"/)
      match && match[1]
    end
  end
end
