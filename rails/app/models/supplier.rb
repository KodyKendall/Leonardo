class Supplier < ApplicationRecord
  has_many :material_supply_rates, dependent: :destroy
  has_many :anchor_supplier_rates, dependent: :destroy
  has_many :tender_specific_material_rates, dependent: :nullify
  validates :name, presence: true, uniqueness: true
end
