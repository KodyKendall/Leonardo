class Supplier < ApplicationRecord
  has_many :material_supply_rates, dependent: :destroy
  validates :name, presence: true, uniqueness: true
end
