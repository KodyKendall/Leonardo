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

    context "on creation" do
      it "populates defaults from equipment type" do
        selection.save!
        expect(selection.base_rate).to eq(1000.0)
        expect(selection.damage_waiver_pct).to eq(0.1)
        expect(selection.diesel_allowance).to eq(200.0)
      end

      it "calculates based on populated defaults" do
        # (1000 * 1.1) + 200 = 1100 + 200 = 1300
        selection.save!
        expect(selection.calculated_monthly_cost).to eq(1300.0)
        # 1300 * 2 units * 3 months = 7800
        expect(selection.total_cost).to eq(7800.0)
      end
    end

    context "when components are updated" do
      it "recalculates calculated_monthly_cost and total_cost" do
        selection.save!
        selection.update!(base_rate: 2000.0, damage_waiver_pct: 0.2, diesel_allowance: 300.0)
        
        # (2000 * 1.2) + 300 = 2400 + 300 = 2700
        expect(selection.calculated_monthly_cost).to eq(2700.0)
        # 2700 * 2 units * 3 months = 16200
        expect(selection.total_cost).to eq(16200.0)
      end
    end
  end
end
