FactoryBot.define do
  factory :line_item_rate_build_up do
    tender_line_item { nil }
    material_supply_rate { "9.99" }
    fabrication_rate { "9.99" }
    fabrication_included { false }
    overheads_rate { "9.99" }
    overheads_included { false }
    shop_priming_rate { "9.99" }
    shop_priming_included { false }
    onsite_painting_rate { "9.99" }
    onsite_painting_included { false }
    delivery_rate { "9.99" }
    delivery_included { false }
    bolts_rate { "9.99" }
    bolts_included { false }
    erection_rate { "9.99" }
    erection_included { false }
    crainage_rate { "9.99" }
    crainage_included { false }
    cherry_picker_rate { "9.99" }
    cherry_picker_included { false }
    galvanizing_rate { "9.99" }
    galvanizing_included { false }
    subtotal { "9.99" }
    margin_amount { "9.99" }
    total_before_rounding { "9.99" }
    rounded_rate { "9.99" }
  end
end
