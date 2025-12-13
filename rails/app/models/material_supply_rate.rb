class MaterialSupplyRate < ApplicationRecord
  belongs_to :material_supply
  belongs_to :supplier
  belongs_to :monthly_material_supply_rate
  
  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit, presence: true, inclusion: { in: %w(tonne), message: "%{value} is not a valid unit" }
  validates :material_supply_id, :supplier_id, :monthly_material_supply_rate_id, presence: true
  
  # When a winner is selected, clear other winners for the same material in this monthly rate
  before_save :clear_other_winners, if: -> { is_winner? && is_winner_changed? }
  
  private
  
  def clear_other_winners
    MaterialSupplyRate
      .where(monthly_material_supply_rate_id: monthly_material_supply_rate_id, material_supply_id: material_supply_id)
      .where.not(id: id)
      .update_all(is_winner: false)
  end
end
