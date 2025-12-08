FactoryBot.define do
  factory :line_item_rate_build_up do
    tender_line_item
    material_supply_rate { 100.0 }
    fabrication_rate { 50.0 }
    overheads_rate { 20.0 }
    delivery_rate { 30.0 }
    bolts_rate { 15.0 }
    erection_rate { 40.0 }
  end
end