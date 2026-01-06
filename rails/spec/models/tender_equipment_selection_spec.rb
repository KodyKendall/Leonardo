require 'rails_helper'

RSpec.describe TenderEquipmentSelection, type: :model do
  let(:tender) { Tender.create!(tender_name: "Test Tender", e_number: "E123", status: "Draft") }
  let(:equipment_type) { EquipmentType.create!(category: :diesel_boom, model: "X100", base_rate_monthly: 1000, diesel_allowance_monthly: 200, damage_waiver_pct: 0.1) }
  
  describe "#calculate_costs" do
    let(:selection) do
      TenderEquipmentSelection.new(
        tender: tender,
        equipment_type: equipment_type,
        units_required: 2,
        period_months: 3
      )
    end

    context "without monthly_cost_override" do
      it "calculates based on equipment type rates" do
        # (1000 + 200) * (1 + 0.1) = 1200 * 1.1 = 1320
        selection.save!
        expect(selection.calculated_monthly_cost).to eq(1320.0)
        # 1320 * 2 units * 3 months = 7920
        expect(selection.total_cost).to eq(7920.0)
      end
    end

    context "with monthly_cost_override" do
      it "uses override and recalculates total_cost" do
        selection.monthly_cost_override = 2500.0
        selection.save!
        expect(selection.calculated_monthly_cost).to eq(2500.0)
        # 2500 * 2 units * 3 months = 15000
        expect(selection.total_cost).to eq(15000.0)
      end
    end
  end
end
