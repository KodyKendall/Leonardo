class TenderSpecificMaterialRate < ApplicationRecord
  # Associations
  belongs_to :tender
  belongs_to :material_supply

  # Validations
  validates :tender_id, presence: true
  validates :material_supply_id, presence: true
  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :tender_id, uniqueness: { scope: :material_supply_id, message: "and material supply combination must be unique" }
  validate :effective_dates_valid

  # Scopes
  scope :active, -> { where("effective_from IS NULL OR effective_from <= ?", Date.current).where("effective_to IS NULL OR effective_to >= ?", Date.current) }

  private

  def effective_dates_valid
    return if effective_from.blank? || effective_to.blank?

    if effective_to <= effective_from
      errors.add(:effective_to, "must be after effective_from")
    end
  end
end
