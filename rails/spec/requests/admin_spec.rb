require "rails_helper"

RSpec.describe "Admin", type: :request do
  let(:admin) { create(:user, admin: true) }
  let(:normal_user) { create(:user, admin: false) }

  describe "GET /admin" do
    it "renders the dashboard in the application layout for admins" do
      sign_in admin
      get admin_root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Admin Dashboard")
      # application.html.erb markers — proves admin no longer uses its own layout
      expect(response.body).to include("cdn.tailwindcss.com")
      expect(response.body).to include(admin_users_path)
    end

    it "redirects non-admins to root" do
      sign_in normal_user
      get admin_root_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /admin/users" do
    it "renders the users list in the application layout" do
      sign_in admin
      get admin_users_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(admin.email)
      expect(response.body).to include("cdn.tailwindcss.com")
    end
  end
end
