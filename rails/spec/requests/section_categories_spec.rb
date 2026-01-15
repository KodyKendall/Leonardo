require 'rails_helper'

RSpec.describe "/section_categories", type: :request do
  let(:user) { create(:user, :admin) }
  before { sign_in user }

  let(:valid_attributes) {
    { name: "steel_sections", display_name: "Steel Sections", supply_rates_type: "material_supply_rates" }
  }

  let(:invalid_attributes) {
    { name: "" }
  }

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        { supply_rates_type: "nuts_bolts_and_washer_supply_rates" }
      }

      it "updates the requested section_category" do
        section_category = SectionCategory.create! valid_attributes
        patch section_category_url(section_category), params: { section_category: new_attributes }
        section_category.reload
        expect(section_category.supply_rates_type).to eq("nuts_bolts_and_washer_supply_rates")
      end

      it "redirects to the section_category" do
        section_category = SectionCategory.create! valid_attributes
        patch section_category_url(section_category), params: { section_category: new_attributes }
        section_category.reload
        expect(response).to redirect_to(section_category_url(section_category))
      end
    end
  end
end
