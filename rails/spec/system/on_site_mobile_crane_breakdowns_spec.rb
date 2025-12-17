# docker compose exec -it llamapress bundle exec rspec spec/system/on_site_mobile_crane_breakdowns_spec.rb --format documentation

require 'rails_helper'

RSpec.describe "OnSiteMobileCraneBreakdowns", type: :feature do
  let(:user) { create(:user) }

  before do
    Capybara.current_driver = :cuprite
    login_as(user, scope: :user)
  end

  describe "editing total roof area and erection rate" do
    it "calculates program duration correctly after editing fields and saving" do
      # Create test data using FactoryBot
      tender = create(:tender)
      breakdown = create(:on_site_mobile_crane_breakdown,
        tender: tender,
        total_roof_area_sqm: 1000.0,
        erection_rate_sqm_per_day: 50.0,
        program_duration_days: 20
      )

      # Go directly to the breakdowns index page
      visit "/on_site_mobile_crane_breakdowns"

      # Wait for the page with edit button
      expect(page).to have_css("[data-testid='edit-button']", wait: 10)

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

      # Verify the database was updated
      breakdown.reload
      expect(breakdown.total_roof_area_sqm).to eq(2000.0)
      expect(breakdown.erection_rate_sqm_per_day).to eq(80.0)
    end
  end
end
