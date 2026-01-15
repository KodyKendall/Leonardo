require 'rails_helper'

RSpec.describe TenderEquipmentSummary, type: :model do
  describe "#calculate!" do
    let(:tender) { create(:tender) }
    let(:equipment_type) { create(:equipment_type, base_rate_monthly: 1000, damage_waiver_pct: 0, diesel_allowance_monthly: 0) }
    
    before do
      # Set total_tonnage if it exists on tender
      if tender.respond_to?(:total_tonnage)
        tender.update!(total_tonnage: 100)
      end
      
      create(:tender_equipment_selection, tender: tender, equipment_type: equipment_type, units_required: 1, period_months: 10, monthly_cost_override: 1000)
      create(:tender_equipment_selection, tender: tender, equipment_type: equipment_type, units_required: 2, period_months: 10, monthly_cost_override: 1000)
    end

    it "calculates total_equipment_cost as sum of selections, establishment_cost and mobilization_fee" do
      summary = tender.tender_equipment_summary
      summary.update!(mobilization_fee: 0, establishment_cost: 5000)
      summary.calculate!
      
      # subtotal = 10000 + 20000 = 30000
      # total = 30000 (subtotal) + 5000 (est) + 0 (mob) = 35000
      expect(summary.equipment_subtotal).to eq(30000)
      expect(summary.total_equipment_cost).to eq(35000)
    end

    it "has 0.0 as mobilization_fee by default in the database" do
      # Create a new tender and manually create a summary to check default
      new_tender = create(:tender)
      new_summary = TenderEquipmentSummary.create!(tender: new_tender)
      expect(new_summary.mobilization_fee).to eq(0)
    end
  end

  describe "P&G sync callback" do
    let(:tender) { create(:tender, total_tonnage: 100) }
    let!(:summary) { create(:tender_equipment_summary, tender: tender) }
    let!(:access_item) { create(:preliminaries_general_item, tender: tender, is_access_equipment: true, category: 'fixed', description: 'Access Item') }

    it "triggers a rate update on associated access P&G items when updated" do
      # Initial state
      allow_any_instance_of(TenderEquipmentSummary).to receive(:cherry_picker_rate_per_tonne).and_return(1500.0)
      access_item.save!
      expect(access_item.reload.rate).to eq(1500.0)

      # Update summary
      allow_any_instance_of(TenderEquipmentSummary).to receive(:cherry_picker_rate_per_tonne).and_return(2500.0)
      
      summary.update!(mobilization_fee: summary.mobilization_fee + 1)
      
      expect(access_item.reload.rate).to eq(2500.0)
    end
  end

  describe "#cherry_picker_rate_per_tonne" do
    let(:tender) { create(:tender, total_tonnage: 100) }
    let(:summary) { create(:tender_equipment_summary, tender: tender, total_equipment_cost: 43160) }

    it "rounds up to the nearest 10" do
      # 43160 / 100 = 431.60
      # (431.60 / 10).ceil * 10 = 44 * 10 = 440
      expect(summary.cherry_picker_rate_per_tonne).to eq(440)
    end

    it "returns 0 if total_equipment_cost is zero" do
      summary.total_equipment_cost = 0
      expect(summary.cherry_picker_rate_per_tonne).to eq(0)
    end

    it "returns 0 if tonnage is zero" do
      tender.update!(total_tonnage: 0)
      expect(summary.cherry_picker_rate_per_tonne).to eq(0)
    end
  end
end
