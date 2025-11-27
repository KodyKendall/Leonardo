class LineItemMaterial < ApplicationRecord
  belongs_to :tender_line_item
  belongs_to :material_supply
  belongs_to :line_item_material_breakdown
end
