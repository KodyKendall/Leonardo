class MaterialSupply < ApplicationRecord
  has_many :material_supply_rates, dependent: :destroy
  has_many :tender_specific_material_rates, dependent: :destroy
  has_many :tenders, through: :tender_specific_material_rates
  validates :name, presence: true, uniqueness: true
  validates :waste_percentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  
  # Enforce static material order across all queries
  default_scope { order(:position) }

  def current_market_rate
    # Find active monthly rate
    active_monthly_rate = MonthlyMaterialSupplyRate
      .where("effective_from <= ?", Date.current)
      .where("effective_to >= ?", Date.current)
      .order(effective_from: :desc)
      .first
    
    return nil unless active_monthly_rate

    # Priority 1: Find winner rate
    winner_rate = material_supply_rates
      .where(monthly_material_supply_rate_id: active_monthly_rate.id, is_winner: true)
      .first

    return winner_rate.rate if winner_rate

    # Priority 2: Find cheapest rate
    cheapest_rate = material_supply_rates
      .where(monthly_material_supply_rate_id: active_monthly_rate.id)
      .order(rate: :asc)
      .first

    return cheapest_rate.rate if cheapest_rate

    nil
  end
end
