FactoryBot.define do
  factory :claim do
    sequence(:claim_number) { |n| "CLM#{n.to_s.rjust(5, '0')}" }
    project
    claim_date { Date.current }
    claim_status { "draft" }
    submitted_by { create(:user) }
  end
end