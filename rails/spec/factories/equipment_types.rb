FactoryBot.define do
  factory :equipment_type do
    category { "diesel_boom" }
    model { "MyString" }
    working_height_m { "9.99" }
    base_rate_monthly { "9.99" }
    damage_waiver_pct { "9.99" }
    diesel_allowance_monthly { "9.99" }
    is_active { false }
  end
end
