class MaterialSupply < ApplicationRecord
  has_many :material_supply_rates, dependent: :destroy
  validates :name, presence: true, uniqueness: true
  validates :waste_percentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
