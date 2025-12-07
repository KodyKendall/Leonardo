FactoryBot.define do
  factory :tender_inclusions_exclusion do
    tender
    description { "Inclusion/Exclusion" }
    category { "inclusion" }
  end
end