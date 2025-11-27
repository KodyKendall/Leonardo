class MonthlyMaterialSupplyRate < ApplicationRecord
  has_many :material_supply_rates, dependent: :destroy
  validates :effective_from, :effective_to, presence: true
  validate :effective_to_after_effective_from

  private

  def effective_to_after_effective_from
    return if effective_to.blank? || effective_from.blank?
    if effective_to <= effective_from
      errors.add(:effective_to, "must be after effective_from")
    end
  end
end
