FactoryBot.define do
  factory :fabrication_record do
    project
    record_month { Date.current.beginning_of_month }
    tonnes_fabricated { 9.99 }
    allowed_rate { 9.99 }
    allowed_amount { 9.99 }
    actual_spend { 9.99 }
  end
end