require 'rails_helper'

RSpec.describe "EquipmentSelections", type: :request do
  let(:user) { User.create!(email: "test@example.com", password: "password") }
  let(:tender) { Tender.create!(tender_name: "Test Tender", e_number: "E123", status: "Draft") }
  let(:equipment_type) { EquipmentType.create!(category: :diesel_boom, model: "X100", base_rate_monthly: 1000, diesel_allowance_monthly: 200) }
  let!(:equipment_selection) do
    TenderEquipmentSelection.create!(
      tender: tender,
      equipment_type: equipment_type,
      units_required: 1,
      period_months: 1,
      purpose: "Testing"
    )
  end

  before do
    sign_in user
  end

  describe "PATCH /tenders/:tender_id/equipment_selections/:id" do
    it "updates the pricing components and returns success" do
      patch tender_equipment_selection_path(tender, equipment_selection), 
            params: { 
              tender_equipment_selection: { 
                base_rate: 2000.0,
                damage_waiver_pct: 0.15,
                diesel_allowance: 250.0
              } 
            },
            as: :turbo_stream

      expect(response).to have_http_status(:ok)
      equipment_selection.reload
      expect(equipment_selection.base_rate).to eq(2000.0)
      expect(equipment_selection.damage_waiver_pct).to eq(0.15)
      expect(equipment_selection.diesel_allowance).to eq(250.0)
      # (2000 * 1.15) + 250 = 2300 + 250 = 2550
      expect(equipment_selection.calculated_monthly_cost).to eq(2550.0)
    end
  end

  describe "DELETE /tenders/:tender_id/equipment_selections/:id" do
    it "destroys the equipment selection and returns a turbo stream response" do
      expect {
        delete tender_equipment_selection_path(tender, equipment_selection), as: :turbo_stream
      }.to change(TenderEquipmentSelection, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end
  end
end
