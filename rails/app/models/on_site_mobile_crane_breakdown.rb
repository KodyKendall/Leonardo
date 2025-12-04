class OnSiteMobileCraneBreakdown < ApplicationRecord
  belongs_to :tender

  validates :tender_id, presence: true, uniqueness: true
  validates :total_roof_area_sqm, :erection_rate_sqm_per_day, numericality: { greater_than_or_equal_to: 0 }
  validates :program_duration_days, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :ownership_type, inclusion: { in: %w[rsb_owned rental], message: "%{value} is not a valid ownership type" }
  validates :splicing_crane_days, :misc_crane_days, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  before_save :calculate_program_duration

  private

  def calculate_program_duration
    if total_roof_area_sqm.zero? || erection_rate_sqm_per_day.zero?
      self.program_duration_days = 0
    else
      self.program_duration_days = (total_roof_area_sqm / erection_rate_sqm_per_day).ceil
    end
  end
end
