class MaterialSupplyRate < ApplicationRecord
  belongs_to :material_supply
  belongs_to :supplier
  belongs_to :monthly_material_supply_rate
  
  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit, presence: true, inclusion: { in: %w(ton), message: "%{value} is not a valid unit" }
  validates :material_supply_id, :supplier_id, :monthly_material_supply_rate_id, presence: true
end
