FactoryBot.define do
  factory :client do
    business_name { "Client#{SecureRandom.hex(4)}" }
    contact_name { "Contact Person" }
    contact_email { "client#{SecureRandom.hex(2)}@example.com" }
  end
end