class LineItemMaterialBreakdown < ApplicationRecord
  belongs_to :tender_line_item
  has_many :line_item_materials, dependent: :destroy

  accepts_nested_attributes_for :line_item_materials, allow_destroy: true, reject_if: :all_blank
end
