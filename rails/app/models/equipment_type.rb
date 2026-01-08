class EquipmentType < ApplicationRecord
  has_many :tender_equipment_selections, dependent: :destroy
  has_many :tenders, through: :tender_equipment_selections

  validates :category, :model, presence: true
  validates :base_rate_monthly, :damage_waiver_pct, :diesel_allowance_monthly, presence: true, numericality: true
  validates :model, uniqueness: { scope: :category, message: "must be unique within category" }

  enum category: {
    diesel_boom: 'diesel_boom',
    electric_scissors: 'electric_scissors',
    diesel_scissors: 'diesel_scissors',
    electric_articulating_booms: 'electric_articulating_booms',
    diesel_articulating_booms: 'diesel_articulating_booms',
    diesel_telescopic_booms: 'diesel_telescopic_booms',
    telehandler: 'telehandler'
  }

  scope :active, -> { where(is_active: true) }
  scope :ordered_by_category_and_height, -> { order(:category, :working_height_m) }

  def monthly_rate_with_waiver
    ((base_rate_monthly || 0) * (1 + (damage_waiver_pct || 0))) + (diesel_allowance_monthly || 0)
  end
end
