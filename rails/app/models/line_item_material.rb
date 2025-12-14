class LineItemMaterial < ApplicationRecord
  belongs_to :tender_line_item, optional: true
  belongs_to :material_supply, optional: true
  belongs_to :line_item_material_breakdown

  # Set tender_line_item from breakdown before validation
  before_validation :set_tender_line_item_from_breakdown
  # Sync material supply rate to rate buildup after save
  after_save :sync_material_supply_rate_to_buildup

  def set_tender_line_item_from_breakdown
    if tender_line_item_id.blank? && line_item_material_breakdown.present?
      self.tender_line_item_id = line_item_material_breakdown.tender_line_item_id
    end
  end
  validates :waste_percentage, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Calculate line total: ((Rate * Waste%) + Rate) * Proportion
  def line_total
    return 0 unless rate.present? && proportion.present?
    waste_percent = waste_percentage.to_f / 100
    waste_amount = rate.to_f * waste_percent
    rate_with_waste = rate.to_f + waste_amount
    (rate_with_waste * proportion.to_f).round(2)
  end

  private

  def sync_material_supply_rate_to_buildup
    # Get the breakdown and its tender line item
    return unless line_item_material_breakdown.present?
    
    tender_line_item = line_item_material_breakdown.tender_line_item
    return unless tender_line_item.present?

    # Get the rate buildup
    rate_buildup = tender_line_item.line_item_rate_build_up
    return unless rate_buildup.present?

    # Calculate the total from all materials in the breakdown (including margin)
    total_material_cost = line_item_material_breakdown.total

    # Update the material supply rate in the rate buildup
    rate_buildup.update(material_supply_rate: total_material_cost)
  end
end
