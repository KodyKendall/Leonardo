FactoryBot.define do
  factory :crane_complement do
    area_min_sqm { "9.99" }
    area_max_sqm { "9.99" }
    crane_recommendation { "MyString" }
    default_wet_rate_per_day { "9.99" }
  end
end
