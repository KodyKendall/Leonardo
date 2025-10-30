require 'rails_helper'

RSpec.describe "/users", type: :request do
  let(:user) {
    User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )
  }

  let(:valid_attributes) {
    { name: "Updated Name" }
  }

  let(:invalid_attributes) {
    { name: "" }
  }

  describe "GET /index" do
    it "renders a successful response when signed in" do
      sign_in user
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
    it "renders a successful response when signed in" do
      sign_in user
      get new_user_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response when signed in" do
      sign_in user
      get edit_user_url(user)
      expect(response).to be_successful
    end
  end

  describe "PATCH /update" do
    it "updates the requested user" do
      sign_in user
      patch user_url(user), params: { user: valid_attributes }
      user.reload
      expect(user.name).to eq("Updated Name")
    end

    it "redirects to the user" do
      sign_in user
      patch user_url(user), params: { user: valid_attributes }
      expect(response).to redirect_to(user_url(user))
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested user" do
      sign_in user
      user_to_delete = user
      expect {
        delete user_url(user_to_delete)
      }.to change(User, :count).by(-1)
    end

    it "redirects to the users list" do
      sign_in user
      delete user_url(user)
      expect(response).to redirect_to(users_url)
    end
  end
end
