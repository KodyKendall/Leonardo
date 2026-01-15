require 'rails_helper'

RSpec.describe "/users", type: :request do
  let(:user) {
    User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User",
      admin: false
    )
  }

  let(:admin_user) {
    User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Admin User",
      role: "admin"
    )
  }

  let(:valid_attributes) {
    { name: "Updated Name", role: "office" }
  }

  let(:invalid_attributes) {
    { name: "" }
  }

  describe "GET /index" do
    it "redirects to root path for non-admin user" do
      sign_in user
      get users_url
      expect(response).to redirect_to(root_url)
      expect(flash[:alert]).to eq("Access Denied.")
    end

    it "renders a successful response for admin user" do
      sign_in admin_user
      get users_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response when signed in" do
      sign_in user
      get user_url(user)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response when signed in as admin" do
      sign_in admin_user
      get new_user_url
      expect(response).to be_successful
    end

    it "redirects non-admin users" do
      sign_in user
      get new_user_url
      expect(response).to redirect_to(root_url)
    end
  end

  describe "GET /edit" do
    it "renders a successful response when signed in" do
      sign_in user
      get edit_user_url(user)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "as admin" do
      it "creates a new User without signing them in" do
        sign_in admin_user
        expect {
          post create_managed_users_url, params: { user: { email: "newuser@example.com", password: "password123", role: "office" } }
        }.to change(User, :count).by(1)
        
        expect(response).to redirect_to(user_url(User.last))
        expect(controller.current_user).to eq(admin_user)
      end
    end
  end

  describe "PATCH /update" do
    context "as admin" do
      it "updates another user" do
        sign_in admin_user
        patch user_url(user), params: { user: { name: "New Name", role: "admin" } }
        user.reload
        expect(user.name).to eq("New Name")
        expect(user.role).to eq("admin")
      end

      it "updates a user without changing the password if blank" do
        sign_in admin_user
        original_encrypted_password = user.encrypted_password
        patch user_url(user), params: { user: { name: "New Name", password: "", password_confirmation: "" } }
        user.reload
        expect(user.encrypted_password).to eq(original_encrypted_password)
        expect(user.name).to eq("New Name")
      end
    end

    context "as regular user" do
      it "can update themselves" do
        sign_in user
        patch user_url(user), params: { user: { name: "Changed" } }
        user.reload
        expect(user.name).to eq("Changed")
      end

      it "cannot update another user" do
        sign_in user
        another_user = User.create!(email: "another@example.com", password: "password123", name: "Another")
        patch user_url(another_user), params: { user: { name: "Changed" } }
        another_user.reload
        expect(another_user.name).to eq("Another")
        expect(response).to redirect_to(root_url)
      end

      it "redirects to the user after update" do
        sign_in user
        patch user_url(user), params: { user: valid_attributes }
        expect(response).to redirect_to(user_url(user))
      end
    end
  end

  describe "DELETE /destroy" do
    context "as admin" do
      it "destroys the requested user" do
        sign_in admin_user
        user_to_delete = User.create!(email: "todelete@example.com", password: "password123", name: "Delete Me")
        expect {
          delete user_url(user_to_delete)
        }.to change(User, :count).by(-1)
      end

      it "redirects to the users list" do
        sign_in admin_user
        user_to_delete = User.create!(email: "todelete@example.com", password: "password123", name: "Delete Me")
        delete user_url(user_to_delete)
        expect(response).to redirect_to(users_url)
      end
    end

    context "as regular user" do
      it "cannot destroy users" do
        sign_in user
        user_to_delete = User.create!(email: "todelete@example.com", password: "password123", name: "Delete Me")
        expect {
          delete user_url(user_to_delete)
        }.not_to change(User, :count)
        expect(response).to redirect_to(root_url)
      end
    end
  end
end
