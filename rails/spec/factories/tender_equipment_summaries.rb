FactoryBot.define do
  factory :tender_equipment_summary do
    tender { nil }
    equipment_subtotal { "9.99" }
    mobilization_fee { "9.99" }
    total_equipment_cost { "9.99" }
    rate_per_tonne_raw { "9.99" }
    rate_per_tonne_rounded { "9.99" }
  end
end
