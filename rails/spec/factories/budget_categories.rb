FactoryBot.define do
  factory :budget_category do
    category_name { "Category#{SecureRandom.hex(4)}" }
    cost_code { "CC#{SecureRandom.hex(2)}" }
    description { "Budget Category" }
  end
end