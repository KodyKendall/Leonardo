FactoryBot.define do
  factory :budget_allowance do
    project { nil }
    budget_category { nil }
    budgeted_amount { "9.99" }
    actual_spend { "9.99" }
    variance { "9.99" }
  end
end
