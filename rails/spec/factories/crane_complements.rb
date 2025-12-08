FactoryBot.define do
  factory :crane_complement do
    area_min_sqm { 100.0 }
    area_max_sqm { 500.0 }
    crane_recommendation { "Medium Crane" }
    default_wet_rate_per_day { 1500.0 }
  end
end