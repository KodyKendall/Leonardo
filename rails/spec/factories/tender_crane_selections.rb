FactoryBot.define do
  factory :tender_crane_selection do
    tender { nil }
    crane_rate { nil }
    purpose { "MyString" }
    quantity { 1 }
    duration_days { 1 }
    wet_rate_per_day { "9.99" }
    total_cost { "9.99" }
    sort_order { 1 }
  end
end
