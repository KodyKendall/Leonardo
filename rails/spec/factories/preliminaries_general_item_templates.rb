FactoryBot.define do
  factory :preliminaries_general_item_template do
    category { "MyString" }
    description { "MyText" }
    quantity { "9.99" }
    rate { "9.99" }
    sort_order { 1 }
    is_crane { false }
    is_access_equipment { false }
  end
end
