class TenderEquipmentSelection < ApplicationRecord
  belongs_to :tender
  belongs_to :equipment_type

  validates :equipment_type_id, :units_required, :period_months, presence: true
  validates :units_required, :period_months, numericality: { greater_than: 0 }
  validates :calculated_monthly_cost, :total_cost, presence: true, numericality: true

  attr_accessor :skip_broadcast
  
  scope :ordered, -> { order(:sort_order) }

  before_validation :calculate_costs
  after_commit :update_tender_equipment_summary, on: [:create, :update, :destroy]
  after_create_commit :broadcast_create
  after_update_commit :broadcast_row_update, unless: :skip_broadcast
  after_destroy_commit :broadcast_destroy
  after_commit :trigger_rate_buildup_update, on: [:create, :update, :destroy]

  private

  def broadcast_create
    broadcast_append_to(
      tender,
      target: "equipment_selections_table",
      partial: "equipment_selections/equipment_selection",
      locals: { equipment_selection: self }
    )
  end

  def broadcast_row_update
    broadcast_replace_to(
      tender,
      target: self,
      partial: "equipment_selections/equipment_selection",
      locals: { equipment_selection: self }
    )
  end

  def broadcast_destroy
    broadcast_remove_to(tender, target: self)
  end

  def calculate_costs
    # Ensure equipment_type_id is present
    return if equipment_type_id.blank?

    # Load equipment_type to get rates
    equipment = EquipmentType.find(equipment_type_id)

    # Calculate monthly cost: (base_rate + diesel_allowance) * (1 + damage_waiver_pct)
    # OR use override if provided
    if monthly_cost_override.present?
      self.calculated_monthly_cost = monthly_cost_override
    else
      base_monthly = equipment.base_rate_monthly + equipment.diesel_allowance_monthly
      damage_multiplier = 1 + (equipment.damage_waiver_pct || 0.06)
      self.calculated_monthly_cost = base_monthly * damage_multiplier
    end

    # Calculate total: (monthly_cost × units × months)
    # Set defaults if units or months are nil
    units = units_required.presence || 1
    months = period_months.presence || 1
    self.total_cost = calculated_monthly_cost * units * months
  end

  def update_tender_equipment_summary
    summary = tender.tender_equipment_summary || tender.create_tender_equipment_summary!
    summary.calculate!
    
    # Broadcast the summary update
    summary.broadcast_update
  end

  # Trigger parent ProjectRateBuildUp to recalculate cherry_picker_rate when equipment selections change
  def trigger_rate_buildup_update
    return unless tender.present?
    
    rate_buildup = tender.project_rate_buildup
    return unless rate_buildup.present?
    
    # Clear cache to ensure fresh calculation
    tender.tender_equipment_summary&.reload
    
    rate_buildup.save!
  end
end
