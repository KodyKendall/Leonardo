FactoryBot.define do
  factory :tender do
    sequence(:e_number) { |n| "E#{n.to_s.rjust(5, '0')}" }
    sequence(:tender_name) { |n| "Tender #{n}" }
    status { "Draft" }
    client_name { "Test Client" }
    tender_value { 100000.00 }
    project_type { "commercial" }
    notes { "Test tender" }
    submission_deadline { Date.current + 30.days }
    awarded_project { nil }

    trait :draft do
      status { "Draft" }
    end

    trait :in_progress do
      status { "In Progress" }
    end

    trait :submitted do
      status { "Submitted" }
      submission_deadline { Date.current - 1.day }
    end

    trait :awarded do
      status { "Awarded" }
    end

    trait :not_awarded do
      status { "Not Awarded" }
    end

    trait :with_client do
      association :client, factory: :client
    end
  end
end
