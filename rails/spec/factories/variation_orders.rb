FactoryBot.define do
  factory :variation_order do
    vo_number { "MyString" }
    project { nil }
    vo_status { "MyString" }
    vo_amount { "9.99" }
    description { "MyText" }
    created_by { nil }
    approved_by { nil }
    approver_notes { "MyText" }
    approved_at { "2025-11-06 11:25:45" }
  end
end
