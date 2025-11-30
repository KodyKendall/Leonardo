require 'rails_helper'

RSpec.describe "Users", type: :system do
  let(:user) {
    User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )
  }

  before do
    # Use Cuprite driver for real browser testing with Chromium
    driven_by(:cuprite)
    sign_in user
  end

  describe "visiting the index" do
    it "displays the users page" do
      visit users_url
      expect(page).to have_selector("h1", text: "Users")
    end
  end

  describe "updating a user" do
    it "successfully updates the user" do
      visit user_url(user)
      click_on "Edit this user", match: :first

      fill_in "Name", with: "Updated Name"
      click_on "Update User"

      expect(page).to have_content("User was successfully updated")
    end
  end

  describe "destroying a user" do
    # Now with Chromium installed, this test will work
    it "successfully destroys the user", js: true do
      visit user_url(user)

      accept_confirm do
        click_on "Destroy this user", match: :first
      end

      expect(page).to have_content("User was successfully destroyed")
    end
  end
end
