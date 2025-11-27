FactoryBot.define do
  factory :line_item_material do
    tender_line_item { nil }
    material_supply { nil }
    proportion { "9.99" }
  end
end
