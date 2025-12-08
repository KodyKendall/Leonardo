FactoryBot.define do
  factory :on_site_mobile_crane_breakdown do
    tender
    total_roof_area_sqm { 1000.0 }
    erection_rate_sqm_per_day { 50.0 }
    program_duration_days { 20 }
    ownership_type { "rental" }
    splicing_crane_required { false }
    misc_crane_required { false }
  end
end