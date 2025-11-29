class LineItemMaterial < ApplicationRecord
  belongs_to :tender_line_item
  belongs_to :material_supply
  belongs_to :line_item_material_breakdown

  validates :material_supply_id, presence: true
  validates :thickness, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Calculate line total: quantity × rate
  def line_total
    return 0 unless quantity.present? && rate.present?
    (quantity * rate).round(2)
  end
end
