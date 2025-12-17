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

  describe "crane checkboxes and dependent fields in builder view" do
    it "disables checkboxes in non-edit mode and shows dependent fields when toggled in edit mode" do
      # Create test data - start with both crane checkboxes unchecked
      tender = create(:tender)
      breakdown = create(:on_site_mobile_crane_breakdown,
        tender: tender,
        splicing_crane_required: false,
        misc_crane_required: false
      )

      # Visit the builder page
      visit "/on_site_mobile_crane_breakdowns/#{breakdown.id}/builder"

      # Wait for page to load
      expect(page).to have_css("[data-testid='edit-button']", wait: 10)

      # --- Acceptance Criteria: Checkboxes are disabled in non-edit mode ---
      splicing_checkbox = find("[data-testid='splicing-crane-required-checkbox']")
      misc_checkbox = find("[data-testid='misc-crane-required-checkbox']")

      expect(splicing_checkbox).to be_disabled
      expect(misc_checkbox).to be_disabled

      # Verify dependent fields are hidden initially
      expect(page).not_to have_css("[data-testid='splicing-crane-size-field']", visible: true)
      expect(page).not_to have_css("[data-testid='splicing-crane-days-field']", visible: true)
      expect(page).not_to have_css("[data-testid='misc-crane-size-field']", visible: true)
      expect(page).not_to have_css("[data-testid='misc-crane-days-field']", visible: true)

      # --- Enter edit mode ---
      find("[data-testid='edit-button']").click

      # --- Acceptance Criteria: Checkboxes are enabled in edit mode ---
      splicing_checkbox = find("[data-testid='splicing-crane-required-checkbox']")
      misc_checkbox = find("[data-testid='misc-crane-required-checkbox']")

      expect(splicing_checkbox).not_to be_disabled
      expect(misc_checkbox).not_to be_disabled

      # --- Acceptance Criteria: Clicking splicing checkbox shows dependent fields ---
      splicing_checkbox.click

      expect(page).to have_css("[data-testid='splicing-crane-size-field']", visible: true, wait: 5)
      expect(page).to have_css("[data-testid='splicing-crane-days-field']", visible: true)

      # --- Acceptance Criteria: Dependent fields are editable in edit mode ---
      splicing_size_input = find("[data-testid='splicing-crane-size-input']")
      splicing_days_input = find("[data-testid='splicing-crane-days-input']")

      expect(splicing_size_input[:readonly]).to be_nil
      expect(splicing_days_input[:readonly]).to be_nil

      # Fill in the fields
      splicing_size_input.set("50T")
      splicing_days_input.set("5")

      # --- Acceptance Criteria: Clicking misc checkbox shows its dependent fields ---
      misc_checkbox.click

      expect(page).to have_css("[data-testid='misc-crane-size-field']", visible: true, wait: 5)
      expect(page).to have_css("[data-testid='misc-crane-days-field']", visible: true)

      misc_size_input = find("[data-testid='misc-crane-size-input']")
      misc_days_input = find("[data-testid='misc-crane-days-input']")

      expect(misc_size_input[:readonly]).to be_nil
      expect(misc_days_input[:readonly]).to be_nil

      # Fill in misc fields
      misc_size_input.set("30T")
      misc_days_input.set("3")

      # --- Acceptance Criteria: Toggling checkbox off hides dependent fields ---
      find("[data-testid='splicing-crane-required-checkbox']").click

      expect(page).not_to have_css("[data-testid='splicing-crane-size-field']", visible: true)
      expect(page).not_to have_css("[data-testid='splicing-crane-days-field']", visible: true)

      # Misc fields should still be visible
      expect(page).to have_css("[data-testid='misc-crane-size-field']", visible: true)
      expect(page).to have_css("[data-testid='misc-crane-days-field']", visible: true)

      # Toggle splicing back on for save
      find("[data-testid='splicing-crane-required-checkbox']").click

      expect(page).to have_css("[data-testid='splicing-crane-size-field']", visible: true, wait: 5)

      # --- Save changes ---
      find("[data-testid='edit-button']").click

      # Wait for turbo stream to re-render the form (checkboxes should be disabled again)
      expect(page).to have_css("[data-testid='splicing-crane-required-checkbox'][disabled]", wait: 10)

      # Verify database was updated
      breakdown.reload
      expect(breakdown.splicing_crane_required).to be true
      expect(breakdown.misc_crane_required).to be true
    end

    it "shows disabled checkboxes with visual indication (greyed out styling)" do
      tender = create(:tender)
      breakdown = create(:on_site_mobile_crane_breakdown,
        tender: tender,
        splicing_crane_required: false,
        misc_crane_required: false
      )

      visit "/on_site_mobile_crane_breakdowns/#{breakdown.id}/builder"
      expect(page).to have_css("[data-testid='edit-button']", wait: 10)

      # Verify checkboxes have disabled attribute in non-edit mode
      splicing_checkbox = find("[data-testid='splicing-crane-required-checkbox']")
      misc_checkbox = find("[data-testid='misc-crane-required-checkbox']")

      expect(splicing_checkbox).to be_disabled
      expect(misc_checkbox).to be_disabled

      # Enter edit mode
      find("[data-testid='edit-button']").click

      # Verify checkboxes are no longer disabled
      splicing_checkbox = find("[data-testid='splicing-crane-required-checkbox']")
      misc_checkbox = find("[data-testid='misc-crane-required-checkbox']")

      expect(splicing_checkbox).not_to be_disabled
      expect(misc_checkbox).not_to be_disabled
    end
  end
end
