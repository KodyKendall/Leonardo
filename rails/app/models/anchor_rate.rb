class AnchorRate < ApplicationRecord
  has_many :anchor_supplier_rates, dependent: :destroy
  has_many :suppliers, through: :anchor_supplier_rates

  validates :name, presence: true, uniqueness: true
  validates :waste_percentage, :material_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Enforce static material order across all queries
  default_scope { order(:position) }
end
