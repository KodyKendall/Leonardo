require 'rails_helper'

RSpec.describe "Equipment Selection Form Reset Bug", type: :feature do
  # Bug: Equipment Selection Form Does Not Reset After Submission
  # Ticket: 2026-01-06 - BUG: Equipment Selection Form Does Not Reset After Submission

  let(:user) { create(:user) }
  let(:tender) { create(:tender) }
  let!(:equipment_type) { create(:equipment_type, model: "JLG 450AJ", category: "diesel_boom", is_active: true, working_height_m: 10) }

  before do
    Capybara.current_driver = :cuprite
    login_as(user, scope: :user)
    visit tender_equipment_selections_path(tender)
  end

  describe "Bug Reproduction: Form does not reset after submission", :js do
    it "retains form values after successful addition (THE BUG)" do
      # 1. Fill out the "Add New Equipment Selection" form
      option_text = "JLG 450AJ (10.0m)"
      find("#tender_equipment_selection_equipment_type_id").find(:option, option_text).select_option
      fill_in "tender_equipment_selection[units_required]", with: "5"
      fill_in "tender_equipment_selection[period_months]", with: "3"
      fill_in "tender_equipment_selection[purpose]", with: "Material handling test"

      # 2. Click "Add Equipment"
      click_button "Add Equipment"

      # 3. Verify the new equipment item appears in the table (to ensure submission was successful)
      # Since it's an editable field in the table, we check the value of the input
      expect(page).to have_field("tender_equipment_selection[purpose]", with: "Material handling test")

      # 4. BUG: Form fields should be reset, but currently they RETAIN values
      # We assert the INCORRECT behavior first to prove the bug, 
      # but according to the TDD mission, I should assert the CORRECT behavior 
      # so that the test FAILS.
      
      # EXPECTED BEHAVIOR (which should fail right now):
      within("#equipment_form") do
        expect(find_field("tender_equipment_selection[units_required]").value).to eq("1")
        expect(find_field("tender_equipment_selection[period_months]").value).to eq("1")
        expect(find_field("tender_equipment_selection[purpose]").value).to eq("")
        # Equipment type should be prompt
        expect(page).to have_select("tender_equipment_selection[equipment_type_id]", selected: "Select equipment...")
      end
    end
  end
end
