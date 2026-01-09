FactoryBot.define do
  factory :nut_bolt_washer_rate do
    sequence(:name) { |n| "Nut Bolt Washer Rate #{n}" }
    waste_percentage { 7.5 }
    material_cost { 10.0 }
  end
end
