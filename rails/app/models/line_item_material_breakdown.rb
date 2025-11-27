class LineItemMaterialBreakdown < ApplicationRecord
  belongs_to :tender_line_item
  has_many :line_item_materials, dependent: :destroy
end
