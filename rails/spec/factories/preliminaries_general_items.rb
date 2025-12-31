FactoryBot.define do
  factory :preliminaries_general_item do
    tender { nil }
    category { "MyString" }
    description { "MyText" }
    quantity { "9.99" }
    rate { "9.99" }
    sort_order { 1 }
  end
end
