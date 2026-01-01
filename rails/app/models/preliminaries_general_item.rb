class PreliminariesGeneralItem < ApplicationRecord
  belongs_to :tender
  belongs_to :preliminaries_general_item_template, optional: true

  enum :category, {
    fixed_based: 'fixed_based',
    duration_based: 'duration_based',
    percentage_based: 'percentage_based'
  }

  validates :category, presence: true
  validates :description, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :rate, numericality: { greater_than_or_equal_to: 0 }

  after_commit :broadcast_builder_update

  private

  def broadcast_builder_update
    # Recalculate the tender's grand total
    tender.recalculate_grand_total!

    # Broadcast the P&G summary update to the tender builder stream
    broadcast_update_to(
      "tender_#{tender.id}_builder",
      target: "tender_#{tender.id}_p_and_g_summary",
      partial: "tenders/p_and_g_summary",
      locals: { tender: tender }
    )
  end
end
