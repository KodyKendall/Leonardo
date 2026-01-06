FactoryBot.define do
  factory :section_category do
    sequence(:name) { |n| "category_#{n}" }
    sequence(:display_name) { |n| "Category #{n}" }
  end
end
