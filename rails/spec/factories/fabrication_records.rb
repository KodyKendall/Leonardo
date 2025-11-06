FactoryBot.define do
  factory :fabrication_record do
    project { nil }
    record_month { "2025-11-06" }
    tonnes_fabricated { "9.99" }
    allowed_rate { "9.99" }
    allowed_amount { "9.99" }
    actual_spend { "9.99" }
  end
end
