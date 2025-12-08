FactoryBot.define do
  factory :material_supply do
    name { "Material#{SecureRandom.hex(4)}" }
    waste_percentage { 5 }
  end
end