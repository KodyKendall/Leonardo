require "rails_helper"

# LP-31: HECVAT AAAI-03 (password policy), AAAI-09 (sign-in audit), AAAI-16 (SSO
# identifier) and the A-series deployment checks (lockout, idle timeout). The code is in
# the llama_bot_rails gem; this runs it through the real app every box serves.
RSpec.describe "Account security (LP-31)", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  POLICY_ENV = %w[
    LLAMAPRESS_SECURITY_PROFILE PASSWORD_MIN_LENGTH PASSWORD_REQUIRED_CLASSES PASSWORD_HISTORY_COUNT
    SESSION_IDLE_TIMEOUT_MINUTES ACCOUNT_LOCKOUT_ATTEMPTS ACCOUNT_LOCKOUT_MINUTES AUDIT_RETENTION_DAYS
  ].freeze

  around do |example|
    saved = POLICY_ENV.to_h { |key| [ key, ENV[key] ] }
    POLICY_ENV.each { |key| ENV.delete(key) }
    example.run
  ensure
    saved.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def set_env(values)
    values.each { |key, value| ENV[key] = value.to_s }
  end

  def strict_policy!
    set_env("PASSWORD_MIN_LENGTH" => 12, "PASSWORD_REQUIRED_CLASSES" => "lower,upper,digit,symbol",
            "PASSWORD_HISTORY_COUNT" => 5)
  end

  # Literal paths throughout: after a request to the engine (/llama_bot/...), the
  # app's url helpers pick up the engine's mount point.
  def events(type)
    LlamaBotRails::ActivityEvent.where(event_type: type)
  end

  def person(email, password = "Earlier-Passw0rd-0", **flags)
    user = User.new(email: email, **flags)
    user.password = password
    user.save!(validate: false)
    user
  end

  def sign_in_form(email, password, env: {})
    post "/users/sign_in", params: { user: { email: email, password: password } }, env: env
  end

  let(:ip) { "203.0.113.10" }

  # --- AAAI-03: password policy -------------------------------------------------

  describe "password policy" do
    it "leaves a box that set nothing on Devise's own rules" do
      post "/users", params: { user: { email: "legacy@example.com", password: "123456", password_confirmation: "123456" } }
      expect(User.find_by(email: "legacy@example.com")).to be_present
    end

    context "with 12 characters, all four classes and 5 remembered passwords" do
      before { strict_policy! }

      it "rejects a short password on sign-up and names the length rule" do
        post "/users", params: { user: { email: "new@example.com", password: "Sh0rt!", password_confirmation: "Sh0rt!" } }
        expect(User.find_by(email: "new@example.com")).to be_nil
        expect(response.body).to include("too short (minimum is 12 characters)")
      end

      it "rejects a reset password without an uppercase letter" do
        user = person("reset@example.com")
        token = user.send_reset_password_instructions
        put "/users/password", params: { user: { reset_password_token: token, password: "alllowercase1!xyz", password_confirmation: "alllowercase1!xyz" } }
        expect(user.reload.valid_password?("alllowercase1!xyz")).to be(false)
        expect(response.body).to include("must include an uppercase letter")
      end

      { "NoDigitsHere!abc" => "must include a number", "NoSymbols12345ab" => "must include a symbol" }.each do |password, message|
        it "rejects #{password} on password change" do
          user = person("change@example.com", "Current-Passw0rd-1")
          sign_in user
          put "/users", params: { user: { current_password: "Current-Passw0rd-1", password: password, password_confirmation: password } }
          expect(user.reload.valid_password?(password)).to be(false)
          expect(response.body).to include(message)
        end
      end

      it "accepts a compliant password on sign-up" do
        post "/users", params: { user: { email: "ok@example.com", password: "Valid-Passw0rd-42", password_confirmation: "Valid-Passw0rd-42" } }
        expect(User.find_by(email: "ok@example.com")).to be_present
      end

      it "applies a changed PASSWORD_MIN_LENGTH" do
        set_env("PASSWORD_MIN_LENGTH" => 16)
        user = User.new(email: "sixteen@example.com", password: "Fourteen-Ch4rs")
        expect(user).not_to be_valid
        expect(user.errors.details[:password]).to include(error: :too_short, count: 16)
      end

      describe "reuse" do
        let(:user) { person("history@example.com", "Earlier-Passw0rd-1") }

        def change_to(password)
          user.password = password
          user.password_confirmation = password
          user.save
        end

        it "blocks the current password without saying which one matched" do
          expect(change_to("Earlier-Passw0rd-1")).to be(false)
          expect(user.errors[:password]).to eq([ LlamaBotRails::SecurityPolicy::REUSE_MESSAGE ])
        end

        it "blocks the 5th previous password" do
          (2..6).each { |n| expect(change_to("Earlier-Passw0rd-#{n}")).to be(true) }
          expect(change_to("Earlier-Passw0rd-1")).to be(false)
        end

        it "allows the 6th previous password" do
          (2..7).each { |n| expect(change_to("Earlier-Passw0rd-#{n}")).to be(true) }
          expect(change_to("Earlier-Passw0rd-1")).to be(true)
        end

        it "stores digests only" do
          change_to("Earlier-Passw0rd-2")
          stored = LlamaBotRails::PasswordHistory.where(user_id: user.id).pluck(:encrypted_password)
          expect(stored.size).to eq(1)
          expect(stored.join).not_to include("Earlier-Passw0rd")
        end
      end

      it "still signs in an existing user with an 8-character password" do
        person("old@example.com", "eight888")
        sign_in_form("old@example.com", "eight888")
        expect(events("auth.login").count).to eq(1)
      end

      it "creates SSO users whose generated password meets the policy" do
        auth = OmniAuth::AuthHash.new(provider: "google_oauth2", uid: "sso-new-1",
                                      info: { email: "sso-new@example.com" },
                                      extra: { raw_info: { email_verified: "true" } })
        user, error = LlamaBotRails::SocialSignIn.resolve_user(User, auth)
        expect(error).to be_nil
        expect(user).to be_persisted
      end
    end

    it "defaults to 12 characters under the institutional profile" do
      set_env("LLAMAPRESS_SECURITY_PROFILE" => "institutional")
      user = User.new(email: "eleven@example.com", password: "Eleven-char")
      expect(user).not_to be_valid
      expect(user.errors.details[:password]).to include(error: :too_short, count: 12)
    end
  end

  # --- AAAI-03: the settings screen ------------------------------------------------

  describe "password policy screen" do
    let(:path) { "/llama_bot/security/password_policy" }
    # The skeleton's users table has no owner (admin) column; there, a security admin
    # is the most senior role.
    let(:owner) { person("owner@example.com", **(User.column_names.include?("admin") ? { admin: true } : { security_admin: true })) }
    let(:security) { person("security@example.com", security_admin: true) }
    let(:standard) { person("standard@example.com") }

    def save_policy(min:, history: 5, classes: [], as: owner, env: {})
      sign_in as
      patch path, params: { security_setting: { password_min_length: min, password_history_count: history, required_classes: classes } }, env: env
    end

    it "opens for an owner and a security admin, not for a standard user" do
      [ owner, security ].each do |user|
        sign_in user
        get path
        expect(response).to have_http_status(:ok)
      end

      sign_in standard
      get path
      expect(response).to have_http_status(:forbidden)
      patch path, params: { security_setting: { password_min_length: 20, password_history_count: 5 } }
      expect(response).to have_http_status(:forbidden)
      expect(LlamaBotRails::SecuritySetting.count).to eq(0)
    end

    it "sends a signed-out visitor to sign in" do
      get path
      expect(response).to have_http_status(:redirect)
      expect(response.location).not_to include("security/password_policy?")
    end

    it "applies a saved minimum to the next password, with no restart" do
      save_policy(min: 16)
      expect(User.new(email: "x@example.com", password: "Fourteen-Ch4rs")).not_to be_valid
    end

    it "wins over the environment" do
      set_env("PASSWORD_MIN_LENGTH" => 12)
      save_policy(min: 16)
      expect(LlamaBotRails::SecurityPolicy.password_policy.min_length).to eq(16)
    end

    it "leaves the environment in charge until something is saved" do
      set_env("PASSWORD_MIN_LENGTH" => 14)
      expect(LlamaBotRails::SecurityPolicy.password_policy.min_length).to eq(14)
    end

    it "refuses a minimum below 12 and says what is allowed" do
      save_policy(min: 4)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("must be between 12 and 128")
      expect(LlamaBotRails::SecuritySetting.count).to eq(0)
    end

    it "shows the live rules on the sign-up form" do
      save_policy(min: 16, classes: %w[upper digit])
      sign_out owner
      get "/users/sign_up"
      expect(response.body).to include("16 characters minimum")
      expect(response.body).to include("including an uppercase letter and a number")
    end

    it "does not lock out a user whose existing password is now too short" do
      person("twelve@example.com", "Twelve-Chars")
      save_policy(min: 16)
      sign_out owner
      sign_in_form("twelve@example.com", "Twelve-Chars")
      expect(events("auth.login").where(actor_id: User.find_by(email: "twelve@example.com").id.to_s).count).to eq(1)
    end

    it "applies a raised history count to passwords set before the change" do
      strict_policy!
      user = person("history@example.com", "Earlier-Passw0rd-1")
      (2..7).each do |n|
        user.password = "Earlier-Passw0rd-#{n}"
        expect(user.save).to be(true)
      end
      save_policy(min: 12, history: 10)
      user.reload.password = "Earlier-Passw0rd-1"
      expect(user.save).to be(false)
    end

    it "audits every change with the admin, IP and both values" do
      set_env("PASSWORD_MIN_LENGTH" => 12)
      save_policy(min: 16, env: { "REMOTE_ADDR" => ip })
      event = events("settings.password_policy_changed").sole
      expect(LlamaBotRails::ActivityEvent.where("event_type LIKE ?", "%security_setting%")).to be_empty
      expect(event.actor_id).to eq(owner.id.to_s)
      expect(event.source_ip).to eq(ip)
      expect(event.metadata.dig("before", "min_length")).to eq(12)
      expect(event.metadata.dig("after", "min_length")).to eq(16)
    end
  end

  # --- AAAI-09: audit events ---------------------------------------------------------

  describe "audit events" do
    let!(:pat) { person("pat@example.edu", "Correct-Passw0rd-1") }

    it "records a sign-in with the user, time and IP" do
      freeze_time do
        sign_in_form(pat.email, "Correct-Passw0rd-1", env: { "REMOTE_ADDR" => ip })
        event = events("auth.login").sole
        expect([ event.actor_id, event.source_ip, event.occurred_at ]).to eq([ pat.id.to_s, ip, Time.current ])
        expect(event.metadata["method"]).to be_present
      end
    end

    it "writes exactly one event for a sign-in request" do
      expect { sign_in_form(pat.email, "Correct-Passw0rd-1") }.to change(LlamaBotRails::ActivityEvent, :count).by(1)
    end

    it "records a sign-out" do
      sign_in_form(pat.email, "Correct-Passw0rd-1")
      delete "/users/sign_out", env: { "REMOTE_ADDR" => ip }
      event = events("auth.logout").sole
      expect([ event.actor_id, event.source_ip, event.metadata["reason"] ]).to eq([ pat.id.to_s, ip, "user" ])
    end

    it "records an idle timeout as a sign-out with reason timeout" do
      set_env("SESSION_IDLE_TIMEOUT_MINUTES" => 30)
      sign_in_form(pat.email, "Correct-Passw0rd-1")
      get "/users/edit"
      expect(response).to have_http_status(:ok)

      travel 31.minutes do
        get "/users/edit"
        # Devise sends a timed-out GET back to the page it asked for, now signed out.
        follow_redirect!
        expect(response).to redirect_to("/users/sign_in")
      end
      expect(events("auth.logout").sole.metadata["reason"]).to eq("timeout")
    end

    it "records a failed sign-in for a known account, without the password" do
      sign_in_form(pat.email, "Wrong-Passw0rd-9", env: { "REMOTE_ADDR" => "203.0.113.20" })
      event = events("auth.login_failed").sole
      expect([ event.actor_id, event.source_ip ]).to eq([ pat.id.to_s, "203.0.113.20" ])
      expect(event.attributes.to_json).not_to include("Wrong-Passw0rd-9")
    end

    it "records a failed sign-in for an unknown account with the attempted email" do
      sign_in_form("nobody@example.edu", "Whatever-1")
      event = events("auth.login_failed").sole
      expect(event.actor_id).to be_nil
      expect(event.metadata["attempted_email"]).to eq("nobody@example.edu")
    end

    it "never stores a password typed into the email field" do
      sign_in_form("hunter2-Secret!", "x")
      expect(events("auth.login_failed").sole.attributes.to_json).not_to include("hunter2-Secret!")
    end

    it "does not count a signed-out visit to a protected page as a failed sign-in" do
      get "/users/edit"
      expect(events("auth.login_failed")).to be_empty
    end

    it "records a mutating request with the user, IP and action, and no password" do
      sign_in pat
      put "/users",
          params: { user: { current_password: "Correct-Passw0rd-1", password: "Newer-Passw0rd-2", password_confirmation: "Newer-Passw0rd-2" } },
          env: { "REMOTE_ADDR" => ip }
      event = LlamaBotRails::ActivityEvent.where(action: "update").sole
      expect([ event.actor_id, event.source_ip ]).to eq([ pat.id.to_s, ip ])
      everything = LlamaBotRails::ActivityEvent.all.map(&:attributes).to_json
      expect(everything).not_to include("Correct-Passw0rd-1")
      expect(everything).not_to include("Newer-Passw0rd-2")
    end

    it "takes the client IP the trusted proxy forwarded" do
      sign_in_form(pat.email, "Correct-Passw0rd-1", env: { "REMOTE_ADDR" => "172.18.0.5", "HTTP_X_FORWARDED_FOR" => ip })
      expect(events("auth.login").sole.source_ip).to eq(ip)
    end

    it "ignores a forged X-Forwarded-For the client put in front of the proxy's entry" do
      sign_in_form(pat.email, "Correct-Passw0rd-1",
                   env: { "REMOTE_ADDR" => "172.18.0.5", "HTTP_X_FORWARDED_FOR" => "10.0.0.1, 198.51.100.7, #{ip}" })
      expect(events("auth.login").sole.source_ip).to eq(ip)
    end

    it "keeps events, with the email, after the user is deleted" do
      sign_in_form(pat.email, "Correct-Passw0rd-1")
      pat.destroy!
      event = events("auth.login").sole
      expect(event.metadata["actor_email"]).to eq("pat@example.edu")
    end
  end

  describe "audit page and CSV" do
    let(:admin) { person("security@example.com", security_admin: true) }
    let(:standard) { person("standard@example.com") }
    let!(:pat) { person("pat@example.edu", "Correct-Passw0rd-1") }

    before do
      set_env("LLAMAPRESS_SECURITY_PROFILE" => "institutional")
      sign_in_form(pat.email, "Correct-Passw0rd-1", env: { "REMOTE_ADDR" => ip })
      reset!
      sign_in_form("=HYPERLINK(\"http://x\")@evil.example", "nope")
      travel_to(3.days.ago) { LlamaBotRails::ActivityEvent.record!("auth.login", actor: admin, metadata: { "ip" => "198.51.100.1" }) }
      reset!
    end

    it "filters by date range, action and user" do
      sign_in admin
      get "/llama_bot/activity", params: { event_type: "auth.login", actor_id: pat.id, from: Date.current.iso8601, to: Date.current.iso8601 }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("pat@example.edu signed in")
      expect(response.body).to include(ip)
      expect(response.body).not_to include("198.51.100.1")
    end

    it "reads sign-in events as sentences with their IP in the feed" do
      sign_in admin
      get "/llama_bot/activity"
      expect(response.body).to include("Failed sign-in for")
      expect(response.body).not_to include("automatically")
    end

    it "is closed to a standard user, page and CSV alike" do
      sign_in standard
      get "/llama_bot/activity"
      expect(response).not_to have_http_status(:ok)
      get "/llama_bot/activity/export.csv"
      expect(response).not_to have_http_status(:ok)
      expect(events("audit.exported")).to be_empty
    end

    it "exports the agreed columns and only matching rows, and audits the export" do
      sign_in admin
      get "/llama_bot/activity/export.csv", params: { event_type: "auth.login", actor_id: pat.id, from: Date.current.iso8601 }
      expect(response).to have_http_status(:ok)
      rows = CSV.parse(response.body)
      expect(rows.first).to eq(%w[occurred_at action user_id user_email source_ip attempted_email detail])
      expect(rows.drop(1).map { |row| row[1] }).to eq([ "auth.login" ])
      expect(rows[1][2..4]).to eq([ pat.id.to_s, "pat@example.edu", ip ])
      exported = events("audit.exported").sole
      expect(exported.actor_id).to eq(admin.id.to_s)
      expect(exported.metadata["rows"]).to eq(1)
    end

    it "neutralises cells a spreadsheet would run as a formula" do
      LlamaBotRails::ActivityEvent.record!("auth.login_failed", metadata: { "attempted_email" => "=cmd|calc@x.example" })
      sign_in admin
      get "/llama_bot/activity/export.csv", params: { event_type: "auth.login_failed" }
      cells = CSV.parse(response.body).drop(1).map { |row| row[5] }
      expect(cells).to include("'=cmd|calc@x.example")
      expect(cells.grep(/\A[=+\-@]/)).to be_empty
    end
  end

  describe "retention" do
    it "keeps everything when AUDIT_RETENTION_DAYS is not set" do
      LlamaBotRails::ActivityEvent.record!("auth.login", occurred_at: 5.years.ago)
      expect(LlamaBotRails::AuditRetention.prune!).to eq(0)
      expect(LlamaBotRails::ActivityEvent.count).to eq(1)
    end

    it "keeps a 364-day-old event and prunes one past the window" do
      set_env("AUDIT_RETENTION_DAYS" => 365)
      kept = LlamaBotRails::ActivityEvent.record!("auth.login", occurred_at: 364.days.ago)
      LlamaBotRails::ActivityEvent.record!("auth.login", occurred_at: 400.days.ago)
      expect(LlamaBotRails::AuditRetention.prune!).to eq(1)
      expect(LlamaBotRails::ActivityEvent.pluck(:id)).to eq([ kept.id ])
    end

    it "refuses a retention under a year at boot" do
      expect { LlamaBotRails::SecurityPolicy.validate_environment!("AUDIT_RETENTION_DAYS" => "30") }
        .to raise_error(LlamaBotRails::SecurityPolicy::ConfigurationError)
    end
  end

  # --- A-series: lockout -------------------------------------------------------------

  describe "lockout" do
    let!(:pat) { person("pat@example.edu", "Correct-Passw0rd-1") }

    it "is off unless configured" do
      8.times { sign_in_form(pat.email, "Wrong-Passw0rd-9") }
      sign_in_form(pat.email, "Correct-Passw0rd-1")
      expect(events("auth.login").count).to eq(1)
    end

    it "locks after 5 failures under the institutional profile, and unlocks after 30 minutes" do
      set_env("LLAMAPRESS_SECURITY_PROFILE" => "institutional")
      5.times { sign_in_form(pat.email, "Wrong-Passw0rd-9") }
      sign_in_form(pat.email, "Correct-Passw0rd-1")
      expect(events("auth.login")).to be_empty
      expect(pat.reload.locked_at).to be_present

      travel 31.minutes do
        sign_in_form(pat.email, "Correct-Passw0rd-1")
      end
      expect(events("auth.login").count).to eq(1)
    end
  end

  # --- AAAI-16: SSO identifier -------------------------------------------------------

  describe "SSO identity" do
    let!(:user) { person("old@example.edu") }
    before { LlamaBotRails::OauthIdentity.create!(user: user, provider: "saml", uid: "abc-123", email: "old@example.edu") }

    def auth(email)
      OmniAuth::AuthHash.new(provider: "saml", uid: "abc-123", info: { email: email })
    end

    it "keeps the account when the email changes at the identity provider" do
      expect {
        resolved, error = LlamaBotRails::SocialSignIn.resolve_user(User, auth("new@example.edu"))
        expect([ resolved, error ]).to eq([ user, nil ])
      }.not_to change { [ User.count, LlamaBotRails::OauthIdentity.count ] }
    end

    it "keeps the account when the email changes in the app" do
      user.update_columns(email: "new@example.edu")
      resolved, = LlamaBotRails::SocialSignIn.resolve_user(User, auth("old@example.edu"))
      expect(resolved).to eq(user)
    end

    it "stores provider and uid in their own columns, unique together" do
      columns = LlamaBotRails::OauthIdentity.column_names
      expect(columns).to include("provider", "uid")
      index = ActiveRecord::Base.connection.indexes(:llama_bot_rails_oauth_identities)
                .find { |i| i.columns == %w[provider uid] }
      expect(index&.unique).to be(true)
    end
  end
end
