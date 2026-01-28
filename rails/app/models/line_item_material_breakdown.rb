class LineItemMaterialBreakdown < ApplicationRecord
  belongs_to :tender_line_item
  has_many :line_item_materials, dependent: :destroy

  accepts_nested_attributes_for :line_item_materials, allow_destroy: true, reject_if: :all_blank
  
  delegate :section_category, to: :tender_line_item, allow_nil: true
  delegate :quantity_based?, to: :section_category, allow_nil: true
  
  # Validate margin percentage
  validates :margin_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :rounding_interval, inclusion: { in: [0, 10, 20, 50, 100] }
  
  # Sync material supply rate to rate buildup after save
  after_save :sync_material_supply_rate_to_buildup

  # Calculate subtotal from all materials
  def subtotal
    # Use SQL for performance on large breakdowns. COALESCE ensures nil values are treated as 0.
    # Quantity-based categories (bolts/anchors) use proportion_percentage as a whole number multiplier.
    line_item_materials.joins(line_item_material_breakdown: { tender_line_item: :section_category })
      .sum("ROUND(CAST(COALESCE(line_item_materials.rate, 0) * (1 + COALESCE(line_item_materials.waste_percentage, 0) / 100.0) * 
        (CASE 
          WHEN section_categories.supply_rates_type IN ('nuts_bolts_and_washer_supply_rates', 'chemical_and_mechanical_anchor_supply_rates') 
          THEN COALESCE(line_item_materials.proportion_percentage, 0) 
          ELSE COALESCE(line_item_materials.proportion_percentage, 0) / 100.0 
        END) AS NUMERIC), 2)").to_f
  end

  # Total before rounding
  def total_before_rounding
    margin_amount = subtotal * (margin_percentage / 100)
    subtotal + margin_amount
  end

  # Calculate total with margin, rounded UP to nearest interval
  def total
    return total_before_rounding if rounding_interval.blank? || rounding_interval.zero?
    
    # Round UP to nearest interval
    (total_before_rounding / rounding_interval.to_f).ceil * rounding_interval
  end

  def populate_from_category(section_category_id)
    # Clear existing materials when switching categories
    line_item_materials.destroy_all

    template = SectionCategoryTemplate.find_by(section_category_id: section_category_id)
    return unless template.present?

    tender = tender_line_item.tender
    template.line_item_material_templates.each do |material_template|
      # Find rate from tender specific rates
      material_rate = tender.tender_specific_material_rates.find_by(
        material_supply_id: material_template.material_supply_id,
        material_supply_type: material_template.material_supply_type
      )&.rate
      
      line_item_materials.create!(
        material_supply_id: material_template.material_supply_id,
        material_supply_type: material_template.material_supply_type,
        proportion_percentage: material_template.proportion_percentage,
        waste_percentage: material_template.waste_percentage || material_template.material_supply&.waste_percentage,
        rate: material_rate
      )
    end
  end

  private

  def sync_material_supply_rate_to_buildup
    # Get the rate buildup
    rate_buildup = tender_line_item.line_item_rate_build_up
    return unless rate_buildup.present?

    # Set the material supply rate with the current total (includes margin) and save to trigger before_save :calculate_totals callback
    rate_buildup.material_supply_rate = total
    rate_buildup.save
  end
end
