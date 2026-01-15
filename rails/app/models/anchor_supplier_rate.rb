class AnchorSupplierRate < ApplicationRecord
  belongs_to :anchor_rate
  belongs_to :supplier

  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :supplier_id, uniqueness: { scope: :anchor_rate_id }

  before_save :clear_other_winners, if: -> { is_winner? && is_winner_changed? }
  after_save :sync_to_anchor_rate, if: -> { is_winner? }
  after_destroy :reset_anchor_rate_cost, if: :is_winner?

  private

  def clear_other_winners
    anchor_rate.anchor_supplier_rates.where.not(id: id).update_all(is_winner: false)
  end

  def sync_to_anchor_rate
    anchor_rate.update!(material_cost: rate)
  end

  def reset_anchor_rate_cost
    anchor_rate.update!(material_cost: 0)
  end
end
