FactoryBot.define do
  factory :crane_rate do
    size { "MyString" }
    ownership_type { "MyString" }
    dry_rate_per_day { "9.99" }
    diesel_per_day { "9.99" }
    is_active { false }
    effective_from { "2025-12-03" }
  end
end
