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
    tender_crane_selections.where(purpose: 'main').sum { |selection| selection.wet_rate_per_day * selection.quantity }
  end

  # Calculate crane cost per tonne using CEILING to nearest R20
  # Returns 0 if financial_tonnage is not available or is zero
  def crainage_rate_per_tonne
    return 0 if total_crane_cost.zero?
    
    # Get financial tonnage from tender (if available)
    tonnage = (tender.respond_to?(:financial_tonnage) && tender.financial_tonnage.present?) ? tender.financial_tonnage.to_f : 0
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
    tender.preliminaries_general_items.where(is_crane: true).find_each(&:save!)
  end
end
