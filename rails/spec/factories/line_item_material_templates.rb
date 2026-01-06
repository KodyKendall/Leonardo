FactoryBot.define do
  factory :line_item_material_template do
    section_category_template { nil }
    material_supply { nil }
    proportion_percentage { "9.99" }
    waste_percentage { "9.99" }
    sort_order { 1 }
  end
end
