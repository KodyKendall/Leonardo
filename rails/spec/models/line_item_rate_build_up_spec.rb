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

    it "rounds up to the specified rounding_interval" do
      rate_buildup.update!(
        material_supply_rate: 101,
        material_supply_included: 1.0,
        margin_percentage: 0,
        rounding_interval: 10
      )
      # 101 rounded up to nearest 10 = 110
      expect(rate_buildup.rounded_rate).to eq(110)

      rate_buildup.update!(rounding_interval: 100)
      # 101 rounded up to nearest 100 = 200
      expect(rate_buildup.rounded_rate).to eq(200)
    end

    it "defaults rounding_interval to 50" do
      expect(rate_buildup.rounding_interval).to eq(50)
      
      rate_buildup.update!(
        material_supply_rate: 101,
        material_supply_included: 1.0,
        margin_percentage: 0
      )
      # 101 rounded up to nearest 50 = 150
      expect(rate_buildup.rounded_rate).to eq(150)
    end

    it "multiplies subtotal by mass_calc before applying margin" do
      rate_buildup.update!(
        material_supply_rate: 100,
        material_supply_included: 1.0,
        mass_calc: 2.0,
        margin_percentage: 10,
        rounding_interval: 10
      )
      # Base subtotal = 100 * 1.0 = 100
      # Effective subtotal used for calculations = 100 * 2.0 = 200
      # Total before rounding = 200 * 1.1 = 220
      # Rounded rate = 220
      expect(rate_buildup.subtotal).to eq(100)
      expect(rate_buildup.total_before_rounding).to eq(220)
      expect(rate_buildup.rounded_rate).to eq(220)
    end

    it "does not round when rounding_interval is 0 (None)" do
      rate_buildup.update!(
        material_supply_rate: 121.50,
        material_supply_included: 1.0,
        margin_percentage: 0,
        rounding_interval: 0
      )
      # 121.50 with no rounding = 121.50
      expect(rate_buildup.rounded_rate).to eq(121.50)
    end

    it "validates rounding_interval inclusion" do
      [0, 10, 20, 50, 100].each do |val|
        rate_buildup.rounding_interval = val
        expect(rate_buildup).to be_valid
      end

      rate_buildup.rounding_interval = 30
      expect(rate_buildup).not_to be_valid
    end
  end

  describe "large multiplier values (enhancement: remove max limit)" do
    let(:tender) { create(:tender) }
    let(:line_item) { create(:tender_line_item, tender: tender) }
    let(:rate_buildup) { line_item.line_item_rate_build_up }

    it "accepts fabrication_included multiplier of 50.0" do
      rate_buildup.fabrication_included = 50.0
      expect(rate_buildup).to be_valid
    end

    it "accepts overheads_included multiplier of 100.0" do
      rate_buildup.overheads_included = 100.0
      expect(rate_buildup).to be_valid
    end

    it "accepts delivery_included multiplier of 999.99" do
      rate_buildup.delivery_included = 999.99
      expect(rate_buildup).to be_valid
    end

    it "calculates correctly with large multipliers" do
      rate_buildup.update!(
        material_supply_rate: 100.0,
        material_supply_included: 1.0,
        fabrication_rate: 50.0,
        fabrication_included: 10.0,
        overheads_rate: 25.0,
        overheads_included: 20.0,
        shop_priming_rate: 0,
        onsite_painting_rate: 0,
        delivery_rate: 0,
        bolts_rate: 0,
        erection_rate: 0,
        crainage_rate: 0,
        cherry_picker_rate: 0,
        galvanizing_rate: 0,
        margin_percentage: 0,
        rounding_interval: 10
      )
      # Subtotal = (100 * 1.0) + (50 * 10.0) + (25 * 20.0) = 100 + 500 + 500 = 1100
      expect(rate_buildup.subtotal).to eq(1100.0)
    end

    it "allows custom items with large included multipliers" do
      rate_buildup.update!(
        material_supply_rate: 0,
        material_supply_included: 0,
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

      custom_item = rate_buildup.rate_buildup_custom_items.build(
        description: "Special Premium Item",
        rate: 50.0,
        included: 100.0
      )

      expect {
        rate_buildup.rate_buildup_custom_items << custom_item
        rate_buildup.save!
      }.not_to raise_error

      # Subtotal = 50 * 100 = 5000
      expect(rate_buildup.reload.subtotal).to eq(5000.0)
    end

    it "verifies the minimum validation boundary is 0.01" do
      # The model has a minimum validation of 0.01 when the field is present and != 0
      # This test documents that boundary requirement
      new_rate_buildup = LineItemRateBuildUp.new(fabrication_included: 0.01)
      new_rate_buildup.validate
      
      # 0.01 should pass (it's the minimum)
      expect(new_rate_buildup.errors[:fabrication_included]).to be_empty
    end

    it "allows 0 as excluded (normalization happens)" do
      # Zero should be allowed because it means "excluded component"
      rate_buildup.fabrication_included = 0
      # The validation only applies if value is present AND != 0
      expect(rate_buildup).to be_valid
    end
  end
end
