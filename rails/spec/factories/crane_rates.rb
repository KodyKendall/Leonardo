FactoryBot.define do
  factory :crane_rate do
    size { "50t" }
    ownership_type { "rental" }
    dry_rate_per_day { 1200.0 }
    diesel_per_day { 150.0 }
    is_active { true }
    effective_from { Date.today }
  end
end