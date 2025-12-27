class TenderEquipmentSummary < ApplicationRecord
  belongs_to :tender

  validates :equipment_subtotal, :mobilization_fee, :total_equipment_cost,
            presence: true, numericality: { greater_than_or_equal_to: 0 }
end
