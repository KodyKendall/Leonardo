class TenderEquipmentSelection < ApplicationRecord
  belongs_to :tender
  belongs_to :equipment_type

  validates :equipment_type_id, :units_required, :period_months, presence: true
  validates :units_required, :period_months, numericality: { greater_than: 0 }
  validates :calculated_monthly_cost, :total_cost, presence: true, numericality: true

  scope :ordered, -> { order(:sort_order) }

  before_validation :calculate_costs
  after_save_commit :update_tender_equipment_summary

  private

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

    # Calculate total: (monthly_cost × units × months) + establishment_cost + de_establishment_cost
    # Set defaults if units or months are nil
    units = units_required.presence || 1
    months = period_months.presence || 1
    monthly_total = calculated_monthly_cost * units * months
    establishment = establishment_cost.presence || 0
    de_establishment = de_establishment_cost.presence || 0
    self.total_cost = monthly_total + establishment + de_establishment
  end

  def update_tender_equipment_summary
    summary = tender.tender_equipment_summary || tender.create_tender_equipment_summary!
    summary.calculate!
    
    # Broadcast the summary update
    summary.broadcast_update
  end
end
