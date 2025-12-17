# docker compose exec -it llamapress bundle exec rspec spec/system/tender_crane_selections_spec.rb --format documentation

require 'rails_helper'

# Use type: :feature instead of :system to use our Cuprite driver config
# (Rails system tests have driver management issues with Cuprite in Docker)
RSpec.describe "TenderCraneSelections", type: :feature do
  let(:user) {
    User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )
  }

  before do
    Capybara.current_driver = :cuprite

    # Ensure user exists
    user

    # Log in via the UI
    visit "/users/sign_in"
    expect(page).to have_field("user_email", wait: 10)
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password123"
    click_button "Log in"

    # Wait for successful login redirect
    expect(page).to have_content("Signed in successfully", wait: 5)
  end

  describe "deleting selected cranes on the builder page" do
    it "removes the crane row from the table without page redirect" do
      # Create test data: a breakdown with a crane selection
      tender = create(:tender)
      crane_rate = create(:crane_rate)
      breakdown = create(:on_site_mobile_crane_breakdown, tender: tender)
      crane_selection = create(:tender_crane_selection,
        tender: tender,
        crane_rate: crane_rate,
        on_site_mobile_crane_breakdown: breakdown,
        purpose: "main",
        quantity: 1,
        duration_days: 10,
        wet_rate_per_day: 1500.00,
        total_cost: 15000.00
      )

      builder_url = "/on_site_mobile_crane_breakdowns/#{breakdown.id}/builder"

      # Navigate to the builder page
      visit builder_url

      # Verify we're on the correct page
      expect(page).to have_current_path(builder_url)
      expect(page).to have_content("Selected Cranes", wait: 10)

      # Verify the crane selection row exists
      expect(page).to have_css("[data-testid='crane-selection-row']", wait: 5)

      # Count the initial number of crane selection rows
      initial_row_count = all("[data-testid='crane-selection-row']").count

      # Store the ID of the first crane selection row for verification
      first_row = first("[data-testid='crane-selection-row']")
      first_row_id = first_row[:id]

      # Verify the crane selection exists in the database before deletion
      expect(TenderCraneSelection.exists?(crane_selection.id)).to be true

      # Click the delete button on the first crane selection
      # Accept the confirmation dialog
      accept_confirm do
        first("[data-testid='delete-crane-button']").click
      end

      # Verify the row is removed from the DOM (turbo stream removes it)
      expect(page).not_to have_css("##{first_row_id}", wait: 5)

      # Verify we stayed on the same page (no redirect)
      expect(page).to have_current_path(builder_url)

      # Verify the crane selection is deleted from the database
      expect(TenderCraneSelection.exists?(crane_selection.id)).to be false

      # Verify the row count decreased by 1 (if there were multiple rows)
      if initial_row_count > 1
        expect(all("[data-testid='crane-selection-row']").count).to eq(initial_row_count - 1)
      else
        # If there was only one row, verify the empty state message appears
        # The summary partial shows "No crane selections yet" when empty
        expect(page).to have_content("No crane selections yet")
      end

      # Verify the page did not do a full reload by checking the turbo frame still exists
      expect(page).to have_css("turbo-frame#tender_crane_selections")
    end
  end
end
