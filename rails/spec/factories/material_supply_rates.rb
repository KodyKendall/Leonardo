FactoryBot.define do
  factory :material_supply_rate do
    material_supply
    supplier
    monthly_material_supply_rate
    unit { "tonne" }
    rate { 1500.0 }
  end
end