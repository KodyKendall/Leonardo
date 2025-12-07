FactoryBot.define do
  factory :variation_order do
    sequence(:vo_number) { |n| "VO-#{n.to_s.rjust(4, '0')}" }
    project
    vo_status { "draft" }
    vo_amount { 10000.0 }
    description { "Variation Order Description" }
    association :created_by, factory: :user
  end
end