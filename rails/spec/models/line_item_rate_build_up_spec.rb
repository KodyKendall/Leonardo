require 'rails_helper'

RSpec.describe LineItemRateBuildUp, type: :model do
  describe "calculation logic" do
    let(:tender) { create(:tender) }
    let(:line_item) { create(:tender_line_item, tender: tender) }
    let(:rate_buildup) { line_item.line_item_rate_build_up }

    it "includes material_supply_rate multiplied by material_supply_included" do
      rate_buildup.update!(
        material_supply_rate: 1000,
        material_supply_included: 0.5,
        fabrication_rate: 0,
        overheads_rate: 0,
        shop_priming_rate: 0,
        onsite_painting_rate: 0,
        delivery_rate: 0,
        bolts_rate: 0,
        erection_rate: 0,
        crainage_rate: 0,
        cherry_picker_rate: 0,
        galvanizing_rate: 0,
        margin_percentage: 0
      )
      # Subtotal should be 1000 * 0.5 = 500
      # Rounded rate (nearest R50 up) = 500
      expect(rate_buildup.subtotal).to eq(500)
      expect(rate_buildup.rounded_rate).to eq(500)
    end

    it "rounds up to nearest R50" do
      rate_buildup.update!(
        material_supply_rate: 100,
        material_supply_included: 1.0,
        margin_percentage: 10 # 100 + 10% = 110
      )
      # 110 rounded up to nearest 50 = 150
      expect(rate_buildup.rounded_rate).to eq(150)
    end
  end
end
