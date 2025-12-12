class LineItemMaterialBreakdown < ApplicationRecord
  belongs_to :tender_line_item
  has_many :line_item_materials, dependent: :destroy

  accepts_nested_attributes_for :line_item_materials, allow_destroy: true, reject_if: :all_blank
  
  # Validate margin percentage
  validates :margin_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  
  # Sync material supply rate to rate buildup after save
  after_save :sync_material_supply_rate_to_buildup

  # Calculate subtotal from all materials
  def subtotal
    line_item_materials.sum(&:line_total).round(2)
  end

  # Calculate total with margin
  def total
    margin_amount = subtotal * (margin_percentage / 100)
    (subtotal + margin_amount).round(2)
  end

  private

  def sync_material_supply_rate_to_buildup
    # Get the rate buildup
    rate_buildup = tender_line_item.line_item_rate_build_up
    return unless rate_buildup.present?

    # Update the material supply rate with the current total (includes margin)
    rate_buildup.update(material_supply_rate: total)
  end
end
