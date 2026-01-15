FactoryBot.define do
  factory :tender_line_item do
    tender
    quantity { 100.0 }
    rate { 50.0 }
    page_number { "Page 1" }
    item_number { "1.1" }
    item_description { "Structural Steel Work" }
    unit_of_measure { "kg" }
    association :section_category
  end
end
