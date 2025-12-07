FactoryBot.define do
  factory :monthly_material_supply_rate do
    effective_from { Date.today }
    effective_to { 1.month.from_now.to_date }
  end
end