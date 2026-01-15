class AnchorRate < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :waste_percentage, :material_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
