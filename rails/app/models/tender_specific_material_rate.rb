class TenderSpecificMaterialRate < ApplicationRecord
  # Associations
  belongs_to :tender
  belongs_to :material_supply, optional: true

  # Validations
  validates :tender_id, presence: true
  validates :material_supply_id, presence: true, if: :rate_present_or_notes_present?
  validates :rate, numericality: { greater_than_or_equal_to: 0 }, if: :rate_present?
  validates :tender_id, uniqueness: { scope: :material_supply_id, message: "and material supply combination must be unique" }, unless: :material_supply_id_blank?
  validate :effective_dates_valid

  # Scopes
  scope :active, -> { where("effective_from IS NULL OR effective_from <= ?", Date.current).where("effective_to IS NULL OR effective_to >= ?", Date.current) }

  private

  def rate_present?
    rate.present?
  end

  def rate_present_or_notes_present?
    rate.present? || notes.present?
  end

  def material_supply_id_blank?
    material_supply_id.blank?
  end

  def effective_dates_valid
    return if effective_from.blank? || effective_to.blank?

    if effective_to <= effective_from
      errors.add(:effective_to, "must be after effective_from")
    end
  end
end
