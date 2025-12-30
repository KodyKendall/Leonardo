class TenderLineItem < ApplicationRecord
  belongs_to :tender, touch: true
  has_one :line_item_rate_build_up, dependent: :destroy
  has_one :line_item_material_breakdown, dependent: :destroy
  has_many :line_item_materials, dependent: :destroy

  accepts_nested_attributes_for :line_item_rate_build_up, allow_destroy: true
  accepts_nested_attributes_for :line_item_material_breakdown, allow_destroy: true

  validates :tender_id, presence: true
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }

  after_initialize :build_defaults, if: :new_record?
  after_create :create_line_item_rate_build_up, if: -> { line_item_rate_build_up.nil? }
  after_create :inherit_inclusion_defaults
  after_create :populate_rates_from_project_buildup
  after_create :create_line_item_material_breakdown, if: -> { line_item_material_breakdown.nil? }
  after_save :update_tender_grand_total
  after_save :update_tender_total_tonnage
  after_destroy :update_tender_grand_total
  after_destroy :update_tender_total_tonnage

  enum section_category: {
    "Blank" => "Blank",
    "Steel Sections" => "Steel Sections",
    "Paintwork" => "Paintwork",
    "Bolts" => "Bolts",
    "Gutter Meter" => "Gutter Meter",
    "M16 Mechanical Anchor" => "M16 Mechanical Anchor",
    "M16 Chemical" => "M16 Chemical",
    "M20 Chemical" => "M20 Chemical",
    "M24 Chemical" => "M24 Chemical",
    "M16 HD Bolt" => "M16 HD Bolt",
    "M20 HD Bolt" => "M20 HD Bolt",
    "M24 HD Bolt" => "M24 HD Bolt",
    "M30 HD Bolt" => "M30 HD Bolt",
    "M36 HD Bolt" => "M36 HD Bolt",
    "M42 HD Bolt" => "M42 HD Bolt"
  }

  # Calculate the total amount for this line item
  def total_amount
    quantity * rate
  end

  private

  def update_tender_grand_total
    tender.recalculate_grand_total!
  end

  def update_tender_total_tonnage
    tender.recalculate_total_tonnage!
  end

  def build_defaults
    build_line_item_rate_build_up unless line_item_rate_build_up
    build_line_item_material_breakdown unless line_item_material_breakdown
  end

  def create_line_item_rate_build_up
    LineItemRateBuildUp.create!(tender_line_item_id: id) unless line_item_rate_build_up
  end

  def populate_rates_from_project_buildup
    return unless line_item_rate_build_up && tender.project_rate_buildup

    project_buildup = tender.project_rate_buildup
    # Use update_columns to avoid triggering normalize_multipliers callback
    # which would override inherited 0.0 inclusion values with 1.0
    line_item_rate_build_up.update_columns(
      material_supply_rate: project_buildup.material_supply_rate,
      fabrication_rate: project_buildup.fabrication_rate,
      overheads_rate: project_buildup.overheads_rate,
      shop_priming_rate: project_buildup.shop_priming_rate,
      onsite_painting_rate: project_buildup.onsite_painting_rate,
      delivery_rate: project_buildup.delivery_rate,
      bolts_rate: project_buildup.bolts_rate,
      erection_rate: project_buildup.erection_rate,
      crainage_rate: project_buildup.crainage_rate,
      cherry_picker_rate: project_buildup.cherry_picker_rate,
      galvanizing_rate: project_buildup.galvanizing_rate,
      shop_drawings_rate: project_buildup.shop_drawings_rate
    )
  end

  def create_line_item_material_breakdown
    LineItemMaterialBreakdown.create!(tender_line_item_id: id) unless line_item_material_breakdown
  end

  def inherit_inclusion_defaults
    return unless line_item_rate_build_up && tender.tender_inclusions_exclusion

    inclusions = tender.tender_inclusions_exclusion
    
    # Map TenderInclusionsExclusion boolean fields to LineItemRateBuildUp decimal fields
    # Includes 4 field name mismatches that need explicit mapping
    inclusion_values = {
      fabrication_included: inclusions.fabrication_included ? 1.0 : 0.0,
      overheads_included: inclusions.overheads_included ? 1.0 : 0.0,
      shop_priming_included: inclusions.primer_included ? 1.0 : 0.0,        # NAME MISMATCH: primer → shop_priming
      onsite_painting_included: inclusions.final_paint_included ? 1.0 : 0.0, # NAME MISMATCH: final_paint → onsite_painting
      delivery_included: inclusions.delivery_included ? 1.0 : 0.0,
      bolts_included: inclusions.bolts_included ? 1.0 : 0.0,
      erection_included: inclusions.erection_included ? 1.0 : 0.0,
      crainage_included: inclusions.crainage_included ? 1.0 : 0.0,
      cherry_picker_included: inclusions.cherry_pickers_included ? 1.0 : 0.0, # NAME MISMATCH: cherry_pickers → cherry_picker
      galvanizing_included: inclusions.steel_galvanized ? 1.0 : 0.0            # NAME MISMATCH: steel_galvanized → galvanizing
    }

    # Update rate buildup with inherited values using update_columns to avoid triggering callbacks
    line_item_rate_build_up.update_columns(inclusion_values)
  end
end
