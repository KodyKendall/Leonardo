FactoryBot.define do
  factory :tender_specific_material_rate do
    tender
    material_supply
    rate { 100.0 }
    unit { "tonne" }
  end
end
