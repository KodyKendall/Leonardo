class TenderEquipmentSelection < ApplicationRecord
  belongs_to :tender
  belongs_to :equipment_type

  validates :units_required, :period_months, presence: true, numericality: { greater_than: 0 }
  validates :calculated_monthly_cost, :total_cost, presence: true, numericality: true

  scope :ordered, -> { order(:sort_order) }
end
