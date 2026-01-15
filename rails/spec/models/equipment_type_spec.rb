require 'rails_helper'

RSpec.describe EquipmentType, type: :model do
  describe "#monthly_rate_with_waiver" do
    it "calculates the monthly rate including damage waiver and diesel allowance" do
      # (1000 * 1.06) + 500 = 1060 + 500 = 1560
      equipment_type = EquipmentType.new(base_rate_monthly: 1000, damage_waiver_pct: 0.06, diesel_allowance_monthly: 500)
      expect(equipment_type.monthly_rate_with_waiver).to eq(1560)
    end

    it "handles nil damage_waiver_pct as 0" do
      # (1000 * 1.0) + 500 = 1500
      equipment_type = EquipmentType.new(base_rate_monthly: 1000, damage_waiver_pct: nil, diesel_allowance_monthly: 500)
      expect(equipment_type.monthly_rate_with_waiver).to eq(1500)
    end

    it "handles nil base_rate_monthly as 0" do
      # (0 * 1.06) + 500 = 500
      equipment_type = EquipmentType.new(base_rate_monthly: nil, damage_waiver_pct: 0.06, diesel_allowance_monthly: 500)
      expect(equipment_type.monthly_rate_with_waiver).to eq(500)
    end

    it "handles nil diesel_allowance_monthly as 0" do
      # (1000 * 1.06) + 0 = 1060
      equipment_type = EquipmentType.new(base_rate_monthly: 1000, damage_waiver_pct: 0.06, diesel_allowance_monthly: nil)
      expect(equipment_type.monthly_rate_with_waiver).to eq(1060)
    end
  end

  describe "scopes" do
    describe ".ordered_by_category_and_height" do
      it "orders by category alphabetically and then by working height ascending" do
        # diesel_scissors comes before electric_scissors
        type_b_mid = EquipmentType.create!(category: :electric_scissors, model: "Electric Mid", base_rate_monthly: 1000, working_height_m: 15.0)
        type_a_high = EquipmentType.create!(category: :diesel_scissors, model: "Diesel High", base_rate_monthly: 1000, working_height_m: 20.0)
        type_a_low = EquipmentType.create!(category: :diesel_scissors, model: "Diesel Low", base_rate_monthly: 1000, working_height_m: 10.0)

        results = EquipmentType.ordered_by_category_and_height
        
        # Expectation:
        # 1. Diesel Low (diesel_scissors, 10.0)
        # 2. Diesel High (diesel_scissors, 20.0)
        # 3. Electric Mid (electric_scissors, 15.0)
        expect(results).to eq([type_a_low, type_a_high, type_b_mid])
      end
    end
  end
end
