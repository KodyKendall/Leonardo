class TenderCraneSelection < ApplicationRecord
  belongs_to :tender
  belongs_to :crane_rate
  belongs_to :on_site_mobile_crane_breakdown, optional: true

  enum purpose: { splicing: 'splicing', main: 'main' }

  before_create :populate_duration_from_breakdown
  before_save :calculate_wet_rate_per_day
  before_save :calculate_total_cost
  after_update_commit :broadcast_summary_update
  after_destroy_commit :broadcast_summary_update

  private

  # Broadcast summary update to the parent breakdown's summary section
  def broadcast_summary_update
    return unless on_site_mobile_crane_breakdown.present?

    breakdown = on_site_mobile_crane_breakdown
    breakdown.broadcast_replace_to(
      [breakdown, "crane_cost_summary"],
      target: "crane_cost_summary",
      partial: "tender_crane_selections/summary",
      locals: { on_site_mobile_crane_breakdown: breakdown }
    )
  end

  # Auto-populate duration_days based on the purpose and breakdown parameters
  # This only runs on create, so it sets the initial value from the breakdown
  def populate_duration_from_breakdown
    return unless on_site_mobile_crane_breakdown.present?

    self.duration_days = case purpose
                         when 'main'
                           on_site_mobile_crane_breakdown.program_duration_days
                         when 'splicing'
                           on_site_mobile_crane_breakdown.splicing_crane_days
                         else
                           0
                         end
  end

  # Calculate wet_rate_per_day from associated crane_rate
  # This ensures wet_rate_per_day is always synced with the crane_rate
  def calculate_wet_rate_per_day
    return unless crane_rate.present?
    self.wet_rate_per_day = crane_rate.wet_rate_per_day
  end

  # Calculate total_cost: quantity × duration_days × wet_rate_per_day
  # This must run after wet_rate_per_day is set, so it's also a before_save callback
  def calculate_total_cost
    # Ensure we have valid values for calculation
    qty = (quantity || 0).to_f
    days = (duration_days || 0).to_f
    rate = (wet_rate_per_day || 0).to_f
    self.total_cost = qty * days * rate
  end
end
