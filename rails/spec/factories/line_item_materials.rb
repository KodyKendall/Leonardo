FactoryBot.define do
  factory :line_item_material do
    line_item_material_breakdown
    tender_line_item
    material_supply
    proportion { "9.99" }
  end
end
