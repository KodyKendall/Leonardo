require 'rails_helper'

RSpec.describe LineItemMaterialBreakdown, type: :model do
  describe "#total" do
    let(:tender) { create(:tender) }
    let(:tender_line_item) { create(:tender_line_item, tender: tender) }
    let(:breakdown) { create(:line_item_material_breakdown, tender_line_item: tender_line_item, margin_percentage: 10) }

    before do
      # Mock subtotal to be 100 for simplicity
      allow(breakdown).to receive(:subtotal).and_return(100.0)
      # 100 + 10% = 110
    end

    it "rounds up to nearest 50 by default" do
      expect(breakdown.rounding_interval).to eq(50)
      expect(breakdown.total).to eq(150)
    end

    it "rounds up to nearest 10" do
      breakdown.rounding_interval = 10
      expect(breakdown.total).to eq(110)
      
      allow(breakdown).to receive(:subtotal).and_return(101.0)
      # 101 + 10.1 = 111.1
      expect(breakdown.total).to eq(120)
    end

    it "rounds up to nearest 20" do
      breakdown.rounding_interval = 20
      expect(breakdown.total).to eq(120)
    end

    it "rounds up to nearest 100" do
      breakdown.rounding_interval = 100
      expect(breakdown.total).to eq(200)
    end

    it "does not round when interval is 0 (None)" do
      breakdown.rounding_interval = 0
      expect(breakdown.total).to eq(110.0)
      
      allow(breakdown).to receive(:subtotal).and_return(101.0)
      expect(breakdown.total).to eq(111.1)
    end
  end

  describe "#subtotal" do
    let(:tender) { Tender.create!(tender_name: "Test", e_number: "E456", status: "Draft") }
    let(:section_category) { SectionCategory.create!(name: "Steel_Subtotal", display_name: "Steel", supply_rates_type: :material_supply_rates) }
    let(:bolt_category) { SectionCategory.create!(name: "Bolts_Subtotal", display_name: "Bolts", supply_rates_type: :nuts_bolts_and_washer_supply_rates) }
    
    it "calculates subtotal correctly for standard categories" do
      tli = TenderLineItem.create!(tender: tender, quantity: 1, rate: 0, section_category: section_category)
      breakdown = tli.line_item_material_breakdown
      breakdown.line_item_materials.create!(rate: 100, proportion_percentage: 50, waste_percentage: 0)
      
      expect(breakdown.reload.subtotal).to eq(50.0)
    end

    it "calculates subtotal correctly for quantity-based categories (bolts)" do
      tli = TenderLineItem.create!(tender: tender, quantity: 1, rate: 0, section_category: bolt_category)
      breakdown = tli.line_item_material_breakdown
      breakdown.line_item_materials.create!(rate: 100, proportion_percentage: 10, waste_percentage: 0)
      
      expect(breakdown.reload.subtotal).to eq(1000.0)
    end
  end
end
