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
end
