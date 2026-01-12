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
end
