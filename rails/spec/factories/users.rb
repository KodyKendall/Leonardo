FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    admin { false }

    trait :admin do
      admin { true }
    end

    after(:create) do |user|
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    end
  end
end
