require "rails_helper"

# Separation of duties (LP-32, HECVAT APPL-05). LlamaBot's half of the same rule is in
# app/tests/test_separation_of_duties.py.
RSpec.describe "Admin separation of duties", type: :request do
  include Devise::Test::IntegrationHelpers

  def person(email, **flags)
    User.create!(email: email, password: "correct-horse-1", **flags)
  end

  let!(:owner) { person("owner@example.com", admin: true) }
  let!(:security) { person("security@example.com", security_admin: true) }
  let!(:system_admin) { person("system@example.com", system_admin: true) }
  let!(:standard) { person("standard@example.com") }

  def events(type)
    LlamaBotRails::ActivityEvent.where(event_type: type)
  end

  describe "the user list" do
    it "is open to a security admin" do
      sign_in security
      get "/admin/users"
      expect(response).to have_http_status(:ok)
    end

    it "is closed to a system admin, and the attempt is logged" do
      sign_in system_admin
      get "/admin/users"
      expect(response).to have_http_status(:forbidden)
      expect(events("access_denied").last.metadata["path"]).to eq("/admin/users")
    end

    it "sends a standard user home, and logs the attempt" do
      sign_in standard
      get "/admin/users"
      expect(response).to redirect_to(root_path)
      expect(events("access_denied").last.metadata["path"]).to eq("/admin/users")
    end

    it "stays open to an existing admin" do
      sign_in owner
      get "/admin/users"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "changing roles" do
    def change(target, **params)
      patch "/admin/users/#{target.id}/update_roles", params: params
    end

    it "is refused to a system admin and changes nothing" do
      sign_in system_admin
      change(standard, security_admin: "1")
      expect(response).to have_http_status(:forbidden)
      expect(standard.reload.security_admin?).to be(false)
    end

    it "is refused to a standard user" do
      sign_in standard
      change(standard, system_admin: "1")
      expect(response).to redirect_to(root_path)
      expect(standard.reload.system_admin?).to be(false)
    end

    it "lets a security admin grant one role, and logs it" do
      sign_in security
      change(standard, system_admin: "1")
      expect(standard.reload.system_admin?).to be(true)
      event = events("role_changed").last
      expect(event.actor_id.to_s).to eq(security.id.to_s)
      expect(event.metadata.dig("after", "system_admin")).to be(true)
      expect(event.human).to be(true)
    end

    it "does not let a security admin raise themselves" do
      sign_in security
      change(security, system_admin: "1")
      expect(security.reload.system_admin?).to be(false)
      expect(events("access_denied").last).to be_present
    end

    it "does not let a security admin give both" do
      sign_in security
      change(standard, security_admin: "1", system_admin: "1", reason: "small team")
      expect(standard.reload).to have_attributes(security_admin?: false, system_admin?: false)
    end

    it "treats adding the second role as giving both" do
      sign_in security
      change(system_admin, security_admin: "1", reason: "small team")
      expect(system_admin.reload.security_admin?).to be(false)
    end

    it "does not let a security admin make an owner or change one" do
      sign_in security
      change(standard, owner: "1")
      expect(standard.reload.owner?).to be(false)
      change(owner, owner: "0")
      expect(owner.reload.owner?).to be(true)
    end

    it "needs a reason even from an owner" do
      sign_in owner
      change(standard, security_admin: "1", system_admin: "1")
      expect(standard.reload.security_admin?).to be(false)
    end

    it "lets an owner give both with a reason, and logs who, whom and why" do
      sign_in owner
      change(standard, security_admin: "1", system_admin: "1", reason: "two-person IT team")
      expect(standard.reload).to have_attributes(security_admin?: true, system_admin?: true)
      event = events("role_changed").last
      expect(event.actor_id.to_s).to eq(owner.id.to_s)
      expect(event.metadata["reason"]).to eq("two-person IT team")
      expect(event.occurred_at).to be_present
    end
  end

  describe "impersonation" do
    def impersonate(target)
      post "/admin/users/#{target.id}/impersonate"
    end

    it "does not let a security admin become a system admin" do
      sign_in security
      impersonate(system_admin)
      expect(response).to have_http_status(:forbidden)
    end

    it "does not let a security admin become an owner" do
      sign_in security
      impersonate(owner)
      expect(response).to have_http_status(:forbidden)
    end

    it "lets a security admin become a standard user, and logs it" do
      sign_in security
      impersonate(standard)
      expect(response).to have_http_status(:redirect)
      expect(events("impersonation_started").last).to be_present
    end

    it "is refused to a system admin" do
      sign_in system_admin
      impersonate(standard)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "the audit log" do
    around do |example|
      original = LlamaBotRails.config.require_authentication
      LlamaBotRails.config.require_authentication = true
      example.run
      LlamaBotRails.config.require_authentication = original
    end

    it "is the security admin's" do
      expect(LlamaBotRails.can?(security, :view_activity)).to be(true)
      expect(LlamaBotRails.can?(owner, :view_activity)).to be(true)
      expect(LlamaBotRails.can?(system_admin, :view_activity)).to be(false)
      expect(LlamaBotRails.can?(standard, :view_activity)).to be(false)
    end
  end

  describe "on a ZDR box" do
    around do |example|
      original = LlamaBotRails.config.require_authentication
      LlamaBotRails.config.require_authentication = false
      example.run
      LlamaBotRails.config.require_authentication = original
    end

    it "keeps the audit log closed even if the app was never locked down" do
      allow(LlamaBotRails::ZdrStatus).to receive(:enforced?).and_return(true)
      expect(LlamaBotRails.can?(system_admin, :view_activity)).to be(false)
      expect(LlamaBotRails.can?(nil, :view_activity)).to be(false)
      expect(LlamaBotRails.can?(security, :view_activity)).to be(true)
    end

    it "leaves an ordinary box as it was" do
      allow(LlamaBotRails::ZdrStatus).to receive(:enforced?).and_return(false)
      expect(LlamaBotRails.can?(system_admin, :view_activity)).to be(true)
    end
  end

  describe "the role model" do
    it "keeps the two administrator roles apart" do
      expect(security).to have_attributes(security_admin?: true, system_admin?: false, standard_user?: false)
      expect(system_admin).to have_attributes(security_admin?: false, system_admin?: true, standard_user?: false)
      expect(standard).to have_attributes(administrator?: false, standard_user?: true)
    end

    it "treats an existing admin as owner, holding both" do
      expect(owner).to have_attributes(owner?: true, security_admin?: true, system_admin?: true)
    end
  end
end
