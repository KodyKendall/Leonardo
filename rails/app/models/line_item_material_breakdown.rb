class LineItemMaterialBreakdown < ApplicationRecord
  belongs_to :tender_line_item
  has_many :line_item_materials, dependent: :destroy

  accepts_nested_attributes_for :line_item_materials, allow_destroy: true, reject_if: :all_blank

  # Calculate subtotal from all materials
  def subtotal
    line_item_materials.sum(&:line_total).round(2)
  end

  # Calculate total (currently same as subtotal, but structure for margin logic)
  def total
    subtotal
  end
end
