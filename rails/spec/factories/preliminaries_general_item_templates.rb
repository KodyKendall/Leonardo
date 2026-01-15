FactoryBot.define do
  factory :preliminaries_general_item_template do
    category { "fixed" }
    description { "Test P&G Template" }
    quantity { 1 }
    rate { 100.00 }
    sort_order { 1 }
    is_crane { false }
    is_access_equipment { false }
  end
end
