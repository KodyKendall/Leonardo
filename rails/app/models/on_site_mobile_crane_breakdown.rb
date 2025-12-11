class OnSiteMobileCraneBreakdown < ApplicationRecord
  belongs_to :tender
  has_many :tender_crane_selections, through: :tender

  validates :tender_id, presence: true, uniqueness: true
  validates :total_roof_area_sqm, :erection_rate_sqm_per_day, numericality: { greater_than_or_equal_to: 0 }
  validates :program_duration_days, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :ownership_type, inclusion: { in: %w[rsb_owned rental], message: "%{value} is not a valid ownership type" }
  validates :splicing_crane_days, :misc_crane_days, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  before_save :calculate_program_duration

  # Calculate total crane cost across all selections
  def total_crane_cost
    tender_crane_selections.sum(:total_cost)
  end

  # Calculate total daily crane rate (sum of wet_rate_per_day × quantity for all selections)
  def total_daily_crane_rate
    tender_crane_selections.sum { |selection| selection.wet_rate_per_day * selection.quantity }
  end

  # Calculate crane cost per tonne using CEILING to nearest R20
  # Returns 0 if total_tonnage is not available or is zero
  def crainage_rate_per_tonne
    return 0 if total_crane_cost.zero?
    
    # Get total tonnage from tender (if available)
    tonnage = tender.respond_to?(:total_tonnage) ? tender.total_tonnage.to_f : 0
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
end
