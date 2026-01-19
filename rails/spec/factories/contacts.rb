FactoryBot.define do
  factory :contact do
    name { "Contact #{SecureRandom.hex(2)}" }
    email { "contact#{SecureRandom.hex(2)}@example.com" }
    phone { "555-#{rand(100..999)}-#{rand(1000..9999)}" }
    is_primary { false }
    client
  end
end
