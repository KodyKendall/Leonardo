FactoryBot.define do
  factory :preliminaries_general_item do
    association :tender
    category { "fixed_based" }
    description { "Test P&G Item" }
    quantity { 1 }
    rate { 100.00 }
    sort_order { 1 }
  end
end
