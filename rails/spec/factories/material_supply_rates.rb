FactoryBot.define do
  factory :material_supply_rate do
    rate { "9.99" }
    unit { "MyString" }
    material_supply { nil }
    supplier { nil }
    monthly_material_supply_rate { nil }
  end
end
