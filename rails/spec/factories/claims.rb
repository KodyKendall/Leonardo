FactoryBot.define do
  factory :claim do
    claim_number { "MyString" }
    project { nil }
    claim_date { "2025-11-06" }
    claim_status { "MyString" }
    total_claimed { "9.99" }
    total_paid { "9.99" }
    amount_due { "9.99" }
    submitted_by { nil }
    notes { "MyText" }
  end
end
