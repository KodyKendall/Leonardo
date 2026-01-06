require 'rails_helper'

RSpec.describe EquipmentType, type: :model do
  describe "#monthly_rate_with_waiver" do
    it "calculates the monthly rate including damage waiver" do
      equipment_type = EquipmentType.new(base_rate_monthly: 1000, damage_waiver_pct: 0.06)
      expect(equipment_type.monthly_rate_with_waiver).to eq(1060)
    end

    it "handles nil damage_waiver_pct as 0" do
      equipment_type = EquipmentType.new(base_rate_monthly: 1000, damage_waiver_pct: nil)
      expect(equipment_type.monthly_rate_with_waiver).to eq(1000)
    end

    it "handles nil base_rate_monthly as 0" do
      equipment_type = EquipmentType.new(base_rate_monthly: nil, damage_waiver_pct: 0.06)
      expect(equipment_type.monthly_rate_with_waiver).to eq(0)
    end
  end
end
