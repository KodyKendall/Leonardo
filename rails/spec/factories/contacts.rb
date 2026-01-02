FactoryBot.define do
  factory :contact do
    name { "MyString" }
    email { "MyString" }
    phone { "MyString" }
    is_primary { false }
    client { nil }
  end
end
