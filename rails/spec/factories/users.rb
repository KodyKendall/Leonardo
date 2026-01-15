FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    role { "quantity_surveyor" }
    admin { false }

    trait :admin do
      admin { true }
      role { "admin" }
    end

    trait :quantity_surveyor do
      role { "quantity_surveyor" }
    end

    trait :office do
      role { "office" }
    end

    trait :material_buyer do
      role { "material_buyer" }
    end

    after(:create) do |user|
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    end
  end
end
