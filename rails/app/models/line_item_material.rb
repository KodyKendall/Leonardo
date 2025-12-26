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
  validates :proportion_percentage, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Calculate line total: Rate * (1 + Waste%) * Proportion%
  def line_total
    return 0 unless rate.present? && proportion_percentage.present?
    waste_percent = waste_percentage.to_f / 100
    proportion_percent = proportion_percentage.to_f / 100
    rate_with_waste = rate.to_f * (1 + waste_percent)
    (rate_with_waste * proportion_percent).round(2)
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

    # Set the material supply rate and save to trigger before_save :calculate_totals callback
    rate_buildup.material_supply_rate = total_material_cost
    rate_buildup.save
  end
end
