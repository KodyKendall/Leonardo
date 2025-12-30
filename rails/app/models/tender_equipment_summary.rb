class TenderEquipmentSummary < ApplicationRecord
  belongs_to :tender

  validates :equipment_subtotal, :mobilization_fee, :total_equipment_cost,
            presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :establishment_cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Calculate equipment costs and rate per tonne
  def calculate!
    # equipment_subtotal = sum of all tender_equipment_selections.total_cost
    self.equipment_subtotal = tender.tender_equipment_selections.sum(:total_cost)

    # total_equipment_cost = equipment_subtotal + mobilization_fee + establishment_cost
    fee = mobilization_fee.presence || 0
    est_cost = establishment_cost.presence || 0
    self.total_equipment_cost = equipment_subtotal + fee + est_cost

    # rate_per_tonne_raw = total_equipment_cost ÷ tender.total_tonnage (raw, no rounding)
    # Handle edge case: if total_tonnage is zero, set to nil
    if tender.total_tonnage.present? && tender.total_tonnage > 0
      self.rate_per_tonne_raw = total_equipment_cost / tender.total_tonnage
    else
      self.rate_per_tonne_raw = nil
    end

    save!
  end

  # Broadcast update to equipment_cost_summary turbo frame
  def broadcast_update
    broadcast_update_to(
      "tender_#{tender.id}",
      target: "equipment_cost_summary",
      partial: "tender_equipment_summaries/summary",
      locals: { tender_equipment_summary: self }
    )
  end
end
