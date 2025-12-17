# docker compose exec -it llamapress bundle exec rspec spec/system/on_site_mobile_crane_breakdowns_spec.rb --format documentation

require 'rails_helper'

RSpec.describe "OnSiteMobileCraneBreakdowns", type: :feature do
  let(:login_email) { ENV.fetch("CAPYBARA_USER_EMAIL", "kody@llamapress.ai") }
  let(:login_password) { ENV.fetch("CAPYBARA_USER_PASSWORD", "123456") }

  before do
    Capybara.current_driver = :cuprite

    visit "/users/sign_in"
    expect(page).to have_field("user_email", wait: 10)
    fill_in "user_email", with: login_email
    fill_in "user_password", with: login_password
    click_button "Log in"

    expect(page).to have_content("Signed in successfully", wait: 5)
  end

  describe "editing total roof area and erection rate" do
    it "calculates program duration correctly after editing fields and saving" do
      # Go directly to the breakdowns index page
      visit "/on_site_mobile_crane_breakdowns"

      # If no breakdowns exist, skip the test
      if page.has_no_css?("[data-testid='edit-button']", wait: 5)
        skip "No mobile crane breakdowns found in the database"
      end

      # Wait for the page with edit button
      expect(page).to have_css("[data-testid='edit-button']", wait: 10)

      # Store the initial values to restore later (use first to handle multiple breakdowns on page)
      initial_roof_area = first("[data-testid='total-roof-area-field']").value
      initial_erection_rate = first("[data-testid='erection-rate-field']").value

      # Click the first edit button to enable editing
      first("[data-testid='edit-button']").click

      # Wait for fields to become editable (readonly attribute removed)
      roof_area_field = first("[data-testid='total-roof-area-field']", wait: 5)
      expect(roof_area_field[:readonly]).to be_nil

      # Clear and fill in new values: 2000 sqm / 80 sqm per day = 25 days
      roof_area_field.set("2000")
      first("[data-testid='erection-rate-field']").set("80")

      # Verify the program duration updates in real-time (client-side calculation)
      # 2000 / 80 = 25 days
      expect(page).to have_css("[data-testid='program-duration-display']", text: "25")

      # Click the checkmark button to save (the edit button becomes a checkmark in edit mode)
      first("[data-testid='edit-button']").click

      # Wait for turbo stream to complete and verify the saved indicator appears
      expect(page).to have_css("[data-testid='saved-indicator']:not(.hidden)", wait: 5)

      # Verify the UI still shows the correct calculated value after save
      expect(page).to have_css("[data-testid='program-duration-display']", text: "25")

      # Restore original values to not pollute the dev database
      first("[data-testid='edit-button']").click
      first("[data-testid='total-roof-area-field']").set(initial_roof_area)
      first("[data-testid='erection-rate-field']").set(initial_erection_rate)
      first("[data-testid='edit-button']").click
      expect(page).to have_css("[data-testid='saved-indicator']:not(.hidden)", wait: 5)
    end
  end
end