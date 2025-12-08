class LineItemMaterial < ApplicationRecord
  belongs_to :tender_line_item, optional: true
  belongs_to :material_supply, optional: true
  belongs_to :line_item_material_breakdown

  # Set tender_line_item from breakdown before validation
  before_validation :set_tender_line_item_from_breakdown

  def set_tender_line_item_from_breakdown
    if tender_line_item_id.blank? && line_item_material_breakdown.present?
      self.tender_line_item_id = line_item_material_breakdown.tender_line_item_id
    end
  end
  validates :waste_percentage, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Calculate line total: rate * (1 + margin%) * quantity
  def line_total
    return 0 unless quantity.present? && rate.present?
    margin_percent = waste_percentage.to_f / 100
    (quantity * rate * (1 + margin_percent)).round(2)
  end
end
