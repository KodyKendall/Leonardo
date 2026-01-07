require 'rails_helper'

RSpec.describe "Crane Selection UI Lag and State Sync", type: :feature do
  let(:user) { create(:user) }
  let(:tender) { create(:tender) }
  let(:breakdown) { create(:on_site_mobile_crane_breakdown, tender: tender) }
  let(:crane_rate) { create(:crane_rate) }
  let!(:selection) { create(:tender_crane_selection, tender: tender, on_site_mobile_crane_breakdown: breakdown, crane_rate: crane_rate, purpose: 'main', quantity: 1, duration_days: 20) }

  before do
    Capybara.current_driver = :cuprite
    user.update!(password: "password123")
    visit "/users/sign_in"
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: "password123"
    click_button "Log in"
    visit builder_on_site_mobile_crane_breakdown_path(breakdown)
  end

  describe "Bug Reproduction: UI State Management", :js do
    it "reproduces the failure where fields are not read-only after save" do
      row_selector = "[data-testid='crane-selection-row']"
      row = first(row_selector)
      within row do
        find("[data-inline-edit-target='editBtn']").click
        fill_in "tender_crane_selection[quantity]", with: 2
        find("[data-inline-edit-target='editBtn']").click
      end
      
      # Wait for save and re-find the row because it might have been replaced by Turbo Stream
      within first(row_selector) do
        expect(find("input[name='tender_crane_selection[quantity]']")[:readonly]).to be_present
      end
    end

    it "reproduces the failure where icon state is brittle on subsequent edits" do
      row_selector = "[data-testid='crane-selection-row']"
      row = first(row_selector)

      # First Edit
      within row do
        find("[data-inline-edit-target='editBtn']").click
        fill_in "tender_crane_selection[quantity]", with: 2
        find("[data-inline-edit-target='editBtn']").click
      end
      
      # Wait for save and check for pencil icon
      expect(page).to have_css("#{row_selector} .fa-pencil")
      
      # Second Edit - This is where the stale listener issue should manifest
      row = first(row_selector)
      within row do
        find("[data-inline-edit-target='editBtn']").click
        expect(page).to have_css(".fa-check")
        fill_in "tender_crane_selection[quantity]", with: 3
        find("[data-inline-edit-target='editBtn']").click
      end

      # Verify it toggles back to pencil
      expect(page).to have_css("#{row_selector} .fa-pencil")
      expect(page).not_to have_css("#{row_selector} .fa-check")
    end

    it "reproduces the failure where unsaved indicator might stay visible" do
      row_selector = "[data-testid='crane-selection-row']"
      row = first(row_selector)

      within row do
        find("[data-inline-edit-target='editBtn']").click
        fill_in "tender_crane_selection[quantity]", with: 5
        
        # Indicator should be visible
        expect(page).to have_css("[data-inline-edit-target='unsavedIndicator']", visible: true)
        
        find("[data-inline-edit-target='editBtn']").click
      end
      
      # After save, it should be hidden
      expect(page).to have_css("#{row_selector} [data-inline-edit-target='unsavedIndicator']", visible: false)
    end

    it "reproduces lag in calculations with many rows" do
      # Create 50 rows to simulate large dataset
      TenderCraneSelection.delete_all
      create_list(:tender_crane_selection, 50, tender: tender, on_site_mobile_crane_breakdown: breakdown, crane_rate: crane_rate, purpose: 'main', quantity: 1, duration_days: 20)
      visit builder_on_site_mobile_crane_breakdown_path(breakdown)
      
      row = all("[data-testid='crane-selection-row']")[25]
      
      within row do
        find("[data-inline-edit-target='editBtn']").click
        
        # Simulate multiple rapid changes
        fill_in "tender_crane_selection[quantity]", with: 10
        fill_in "tender_crane_selection[duration_days]", with: 30
        
        # Verify calculation eventually reflects latest change
        # 10 * 30 * 1350 = 405000
        # Wait a moment for the debounce
        sleep 0.2
        expect(find("input[data-total-cost-display]").value).to include("405000.00")
      end
    end
  end
end
