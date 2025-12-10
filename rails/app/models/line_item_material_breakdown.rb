class LineItemMaterialBreakdown < ApplicationRecord
  belongs_to :tender_line_item
  has_many :line_item_materials, dependent: :destroy

  accepts_nested_attributes_for :line_item_materials, allow_destroy: true, reject_if: :all_blank
  
  # Sync material supply rate to rate buildup after save
  after_save :sync_material_supply_rate_to_buildup

  # Calculate subtotal from all materials
  def subtotal
    line_item_materials.sum(&:line_total).round(2)
  end

  # Calculate total (currently same as subtotal, but structure for margin logic)
  def total
    subtotal
  end

  private

  def sync_material_supply_rate_to_buildup
    # Get the rate buildup
    rate_buildup = tender_line_item.line_item_rate_build_up
    return unless rate_buildup.present?

    # Update the material supply rate with the current subtotal
    rate_buildup.update(material_supply_rate: subtotal)
  end
end
