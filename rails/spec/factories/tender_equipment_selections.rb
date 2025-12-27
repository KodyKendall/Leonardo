FactoryBot.define do
  factory :tender_equipment_selection do
    tender { nil }
    equipment_type { nil }
    units_required { 1 }
    period_months { 1 }
    purpose { "MyString" }
    monthly_cost_override { "9.99" }
    calculated_monthly_cost { "9.99" }
    total_cost { "9.99" }
    sort_order { 1 }
  end
end
