class MaterialSupply < ApplicationRecord
  has_many :material_supply_rates, dependent: :destroy
  has_many :tender_specific_material_rates, dependent: :destroy
  has_many :tenders, through: :tender_specific_material_rates
  validates :name, presence: true, uniqueness: true
  validates :waste_percentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  
  # Enforce static material order across all queries
  default_scope { order(:position) }
end
