require 'rails_helper'

# Use type: :feature instead of :system to use our Cuprite driver config
# (Rails system tests have driver management issues with Cuprite in Docker)
RSpec.describe "Users", type: :feature do
  # Use existing user credentials since we're testing against the running dev server
  let(:login_email) { ENV.fetch("CAPYBARA_USER_EMAIL", "kody@llamapress.ai") }
  let(:login_password) { ENV.fetch("CAPYBARA_USER_PASSWORD", "123456") }

  before do
    Capybara.current_driver = :cuprite

    # Log in via the UI since we're testing against an external server
    visit "/users/sign_in"
    expect(page).to have_field("user_email", wait: 10)
    fill_in "user_email", with: login_email
    fill_in "user_password", with: login_password
    click_button "Log in"

    # Wait for successful login redirect
    expect(page).to have_content("Signed in successfully", wait: 5)
  end

  describe "visiting the index" do
    it "displays the users page" do
      visit users_path
      expect(page).to have_selector("h1", text: "Users")
    end
  end

  # describe "updating a user" do
  #   it "successfully updates the user" do
  #     visit user_url(user)
  #     click_on "Edit this user", match: :first

  #     fill_in "Name", with: "Updated Name"
  #     click_on "Update User"

  #     expect(page).to have_content("User was successfully updated")
  #   end
  # end

  # describe "destroying a user" do
  #   # Now with Chromium installed, this test will work
  #   it "successfully destroys the user", js: true do
  #     visit user_url(user)

  #     accept_confirm do
  #       click_on "Destroy this user", match: :first
  #     end

  #     expect(page).to have_content("User was successfully destroyed")
  #   end
  # end
end
