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

  def set_crane_defaults
    return unless preliminaries_general_item_template&.is_crane? || is_crane?

    self.is_crane = true if preliminaries_general_item_template&.is_crane?

    # Inherit quantity from tender's total tonnes (default to 1 if 0)
    if quantity.to_f.zero? || quantity == 1
      self.quantity = (tender.total_tonnage.to_f > 0 ? tender.total_tonnage : 1)
    end
    
    # Inherit rate from tender's crane breakdown
    if rate.to_f.zero?
      crane_breakdown = tender.on_site_mobile_crane_breakdown
      self.rate = crane_breakdown&.crainage_rate_per_tonne || 0
    end
  end

  def set_access_equipment_defaults
    return unless preliminaries_general_item_template&.is_access_equipment? || is_access_equipment?

    self.is_access_equipment = true if preliminaries_general_item_template&.is_access_equipment?

    # Inherit quantity from tender's total tonnage (default to 1 if 0)
    if quantity.to_f.zero? || quantity == 1
      self.quantity = (tender.total_tonnage.to_f > 0 ? tender.total_tonnage : 1)
    end

    # Inherit rate from tender's equipment summary rounded to nearest R20
    if rate.to_f.zero?
      self.rate = tender.tender_equipment_summary&.cherry_picker_rate_per_tonne || 0
    end
  end

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
