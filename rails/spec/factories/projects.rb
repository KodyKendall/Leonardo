FactoryBot.define do
  factory :project do
    rsb_number { "MyString" }
    tender { nil }
    project_status { "MyString" }
    project_start_date { "2025-11-06" }
    project_end_date { "2025-11-06" }
    budget_total { "9.99" }
    actual_spend { "9.99" }
    created_by { nil }
  end
end
