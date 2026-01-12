class PreliminariesGeneralItem < ApplicationRecord
  belongs_to :tender
  belongs_to :preliminaries_general_item_template, optional: true

  enum :category, {
    fixed: 'fixed',
    time_based: 'time_based',
    percentage_based: 'percentage_based'
  }

  validates :category, presence: true
  validates :description, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :rate, numericality: { greater_than_or_equal_to: 0 }

  after_commit :broadcast_builder_update
  after_update_commit :broadcast_row_update
  before_save :recalculate_equipment_rates!

  def recalculate_equipment_rates!
    if is_crane?
      # Inherit rate from tender's crane breakdown
      crane_breakdown = tender.on_site_mobile_crane_breakdown
      self.rate = crane_breakdown&.crainage_rate_per_tonne || 0
    elsif is_access_equipment?
      # Inherit rate from tender's equipment summary
      self.rate = tender.tender_equipment_summary&.cherry_picker_rate_per_tonne || 0
    end
  end

  def set_crane_defaults
    return unless preliminaries_general_item_template&.is_crane? || is_crane?

    self.is_crane = true if preliminaries_general_item_template&.is_crane?

    # Inherit quantity from tender's financial tonnes (default to 1 if 0)
    if quantity.to_f.zero? || quantity == 1
      self.quantity = (tender.financial_tonnage.to_f > 0 ? tender.financial_tonnage : 1)
    end
    
    recalculate_equipment_rates!
  end

  def set_access_equipment_defaults
    return unless preliminaries_general_item_template&.is_access_equipment? || is_access_equipment?

    self.is_access_equipment = true if preliminaries_general_item_template&.is_access_equipment?

    # Inherit quantity from tender's financial tonnage (default to 1 if 0)
    if quantity.to_f.zero? || quantity == 1
      self.quantity = (tender.financial_tonnage.to_f > 0 ? tender.financial_tonnage : 1)
    end

    recalculate_equipment_rates!
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

  def broadcast_row_update
    if saved_change_to_category?
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
    else
      broadcast_replace_to(
        "tender_#{tender.id}_pg_items",
        target: self,
        partial: "preliminaries_general_items/preliminaries_general_item",
        locals: { 
          preliminaries_general_item: self, 
          tender: tender,
          templates: PreliminariesGeneralItemTemplate.order(:description)
        }
      )

      broadcast_replace_to(
        "tender_#{tender.id}_pg_items",
        target: "pg_totals",
        partial: "preliminaries_general_items/totals",
        locals: { tender: tender }
      )
    end
  end
end
