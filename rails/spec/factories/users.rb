FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    role { "project_manager" }
    admin { false }

    trait :admin do
      admin { true }
      role { "admin" }
    end

    trait :project_manager do
      role { "project_manager" }
    end

    trait :estimator do
      role { "estimator" }
    end

    after(:create) do |user|
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    end
  end
end
