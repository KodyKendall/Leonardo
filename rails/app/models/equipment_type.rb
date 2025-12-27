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
    telehandler: 'telehandler'
  }

  scope :active, -> { where(is_active: true) }
end
