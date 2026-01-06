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
    it "updates the monthly_cost_override and returns success" do
      patch tender_equipment_selection_path(tender, equipment_selection), 
            params: { tender_equipment_selection: { monthly_cost_override: 2500.0 } },
            as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(equipment_selection.reload.monthly_cost_override).to eq(2500.0)
      expect(equipment_selection.calculated_monthly_cost).to eq(2500.0)
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
