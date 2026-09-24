# frozen_string_literal: true

# Sign-in hardening for the cold-load race with the LlamaBot pane.
#
# What happened (leo-rozeze, 2026-09-07 21:05 UTC, minutes before a customer kickoff
# call): a browser with no session cookie opened the app inside LlamaBot. The chat pane
# requested /llama_bot/conversations (-> /llama_bot/sign_in) at the same moment the app
# iframe requested / (-> /users/sign_in). Both responses minted a brand-new session
# cookie; the browser kept whichever landed last. The sign-in form's authenticity_token
# belonged to the other one, so the POST failed with InvalidAuthenticityToken and the
# Leonardo error page ("Can't verify CSRF token authenticity") instead of signing in. A
# reload fixes it, which is why it looked random.
#
# Reproducible with curl: GET /users/sign_in (cookie A, token A), GET /llama_bot/sign_in
# with no cookie (cookie B), POST /users/sign_in with token A + cookie B.
#
# Two layers:
#   1. The form asks for a token bound to the cookie the browser holds AT SUBMIT TIME
#      (GET /users/sign_in/token, below) and swaps it in before posting.
#   2. If a stale token still gets through, re-render the form with a fresh token and a
#      plain message instead of raising into the error page.
#
# Deliberately NOT `protect_from_forgery with: :reset_session`. That also makes the
# symptom go away, but by abandoning CSRF verification on the one POST where a session
# is established — and it does it silently, so nobody learns the race is still there.
# Layer 1 means the mismatch normally never happens; layer 2 costs the user one extra
# click in the case where JS could not run.
class Users::SessionsController < Devise::SessionsController
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_fresh_sign_in_form

  # GET /users/sign_in/token — a CSRF token for the session cookie on THIS request.
  # No auth (Devise controllers skip authenticate_user!), and never cached:
  # ApplicationController#set_context puts no-store on every response, which matters
  # here more than anywhere — a cached token is a token for somebody else's cookie.
  def csrf_token
    render json: { token: form_authenticity_token }
  end

  private

  def render_fresh_sign_in_form
    # An unverified POST must never sign anyone in. Devise authenticates lazily from the
    # posted email/password the moment the layout asks for current_user (the SI#187
    # mechanism), which would quietly log the user in from a request we just rejected.
    request.env["devise.allow_params_authentication"] = false
    warden.clear_strategies_cache!(scope: :user)
    sign_out(:user) if warden.user(:user)

    self.resource = resource_class.new(email: params.dig(:user, :email))
    # Not flash: the skeleton's application layout renders no flash, so the message
    # would vanish and the re-render would look like the form did nothing at all.
    @sign_in_notice = "That sign-in page had expired. Please enter your password and press Sign in again."
    render :new, status: :unprocessable_entity
  end
end
