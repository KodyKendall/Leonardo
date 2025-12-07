FactoryBot.define do
  factory :boq_item do
    sequence(:item_number) { |n| "ITEM-#{n}" }
    item_description { "Steel Section" }
    unit_of_measure { "Tonne" }
    quantity { 10.5 }
    section_category { "Steel Sections" }
    sequence_order { 1 }
    notes { "Test item" }
    page_number { "1" }
    association :boq

    trait :bolts do
      section_category { "Bolts" }
      item_description { "M16 Bolts" }
      unit_of_measure { "Box" }
      quantity { 100 }
    end

    trait :paintwork do
      section_category { "Paintwork" }
      item_description { "Primer Paint" }
      unit_of_measure { "Litre" }
      quantity { 50 }
    end

    trait :mechanical_anchor do
      section_category { "M16 Mechanical Anchor" }
      item_description { "M16 Mechanical Anchors" }
      unit_of_measure { "Piece" }
      quantity { 200 }
    end

    trait :chemical_anchor do
      section_category { "M16 Chemical" }
      item_description { "M16 Chemical Anchors" }
      unit_of_measure { "Piece" }
      quantity { 150 }
    end

    trait :hd_bolt do
      section_category { "M20 HD Bolt" }
      item_description { "M20 HD Bolts" }
      unit_of_measure { "Box" }
      quantity { 50 }
    end

    trait :gutter do
      section_category { "Gutter Meter" }
      item_description { "Gutter Meter" }
      unit_of_measure { "Metre" }
      quantity { 100.5 }
    end
  end
end
