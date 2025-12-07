FactoryBot.define do
  factory :supplier do
    name { "Supplier#{SecureRandom.hex(4)}" }
  end
end