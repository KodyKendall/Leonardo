class TenderEquipmentSummary < ApplicationRecord
  belongs_to :tender

  validates :equipment_subtotal, :mobilization_fee, :total_equipment_cost,
            presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :establishment_cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  after_update_commit :broadcast_update
  after_update_commit :sync_access_pg_items

  ACCESS_EQUIPMENT_ROUNDING_FACTOR = 10

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

  # Calculate cherry picker rate per tonne using CEILING to nearest factor (standardized to 10)
  # Returns 0 if total_equipment_cost is not available or is zero
  def cherry_picker_rate_per_tonne
    return 0 if total_equipment_cost.blank? || total_equipment_cost.zero?
    
    # Get total tonnage from tender (if available)
    tonnage = (tender.respond_to?(:total_tonnage) && tender.total_tonnage.present?) ? tender.total_tonnage.to_f : 0
    return 0 if tonnage.zero?
    
    rate = total_equipment_cost / tonnage
    (rate / ACCESS_EQUIPMENT_ROUNDING_FACTOR.to_f).ceil * ACCESS_EQUIPMENT_ROUNDING_FACTOR
  end

  # Broadcast update to equipment_cost_summary turbo frame
  def broadcast_update
    broadcast_replace_to(
      tender,
      target: "equipment_cost_summary",
      partial: "tender_equipment_summaries/summary",
      locals: { tender_equipment_summary: self }
    )
  end

  def sync_access_pg_items
    items = tender.preliminaries_general_items.where(is_access_equipment: true)
    return if items.empty?

    new_rate = cherry_picker_rate_per_tonne
    
    # Update all items without triggering individual callbacks/broadcasts
    items.update_all(rate: new_rate, updated_at: Time.current)
    
    # Trigger a single grand total recalculation and broadcast
    tender.recalculate_grand_total!
    
    # Broadcast the P&G summary update
    broadcast_update_to(
      "tender_#{tender.id}_builder",
      target: "tender_#{tender.id}_p_and_g_summary",
      partial: "tenders/p_and_g_summary",
      locals: { tender: tender }
    )
    
    # Force a refresh of the P&G items container to show updated rates
    broadcast_replace_to(
      "tender_#{tender.id}_pg_items",
      target: "preliminaries_general_items_container",
      partial: "preliminaries_general_items/grouped_items",
      locals: { 
        tender: tender, 
        grouped_items: tender.preliminaries_general_items.order(:sort_order, :created_at).group_by(&:category),
        templates: PreliminariesGeneralItemTemplate.order(:description)
      }
    )
  end
end
