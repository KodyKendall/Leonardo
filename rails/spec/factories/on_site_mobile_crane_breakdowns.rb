FactoryBot.define do
  factory :on_site_mobile_crane_breakdown do
    tender_id { "" }
    total_roof_area_sqm { "9.99" }
    erection_rate_sqm_per_day { "9.99" }
    program_duration_days { 1 }
    ownership_type { "MyString" }
    splicing_crane_required { false }
    splicing_crane_size { "MyString" }
    splicing_crane_days { 1 }
    misc_crane_required { false }
    misc_crane_size { "MyString" }
    misc_crane_days { 1 }
  end
end
