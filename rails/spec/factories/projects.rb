FactoryBot.define do
  factory :project do
    rsb_number { "RSB#{rand(10000)}" }
    tender
    project_status { "active" }
    budget_total { "9.99" }
    actual_spend { "9.99" }
    created_by { create(:user) }
  end
end