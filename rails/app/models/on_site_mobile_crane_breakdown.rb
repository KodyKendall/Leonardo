class OnSiteMobileCraneBreakdown < ApplicationRecord
  belongs_to :tender
  has_many :tender_crane_selections, through: :tender

  validates :tender_id, presence: true, uniqueness: true
  validates :total_roof_area_sqm, :erection_rate_sqm_per_day, numericality: { greater_than_or_equal_to: 0 }
  validates :program_duration_days, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :ownership_type, inclusion: { in: %w[rsb_owned rental], message: "%{value} is not a valid ownership type" }
  validates :splicing_crane_days, :misc_crane_days, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :splicing_crane_size, :misc_crane_size, format: { with: /\A\d+t\z/, message: "must be in format 50t (number + lowercase t)", allow_blank: true }

  before_save :calculate_program_duration
  after_update_commit :broadcast_complements_update
  after_update_commit :sync_crane_pg_items

  # Calculate total crane cost across all selections
  def total_crane_cost
    tender_crane_selections.sum(:total_cost)
  end

  # Calculate total daily crane rate for MAIN cranes only (sum of wet_rate_per_day × quantity)
  def total_daily_crane_rate
    tender_crane_selections.where(purpose: 'main').sum('wet_rate_per_day * quantity')
  end

  # Calculate crane cost per tonne using CEILING to nearest R20
  # Returns 0 if total_tonnage is not available or is zero
  def crainage_rate_per_tonne
    return 0 if total_crane_cost.zero?
    
    # Get total tonnage from tender (if available)
    tonnage = (tender.respond_to?(:total_tonnage) && tender.total_tonnage.present?) ? tender.total_tonnage.to_f : 0
    return 0 if tonnage.zero?
    
    rate = total_crane_cost / tonnage
    (rate / 20).ceil * 20
  end

  private

  def calculate_program_duration
    if total_roof_area_sqm.zero? || erection_rate_sqm_per_day.zero?
      self.program_duration_days = 0
    else
      self.program_duration_days = (total_roof_area_sqm / erection_rate_sqm_per_day).ceil
    end
  end

  def broadcast_complements_update
    # Broadcast update to crane complements table when erection rate changes
    frame_id = "on_site_mobile_crane_breakdown_#{id}_crane_complements_table"
    
    broadcast_replace_later_to(
      "on_site_mobile_crane_breakdown_#{id}",
      target: frame_id,
      partial: "crane_complements/builder_table",
      locals: {
        on_site_mobile_crane_breakdown_id: id
      }
    )
  end

  def sync_crane_pg_items
    items = tender.preliminaries_general_items.where(is_crane: true)
    return if items.empty?

    new_rate = crainage_rate_per_tonne
    
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
