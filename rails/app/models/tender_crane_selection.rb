class TenderCraneSelection < ApplicationRecord
  belongs_to :tender
  belongs_to :crane_rate
  belongs_to :on_site_mobile_crane_breakdown, optional: true

  enum purpose: { splicing: 'splicing', main: 'main', misc: 'misc' }

  before_create :populate_duration_from_breakdown
  before_save :calculate_wet_rate_per_day
  before_save :calculate_total_cost
  after_save :verify_total_cost_calculated
  after_commit :trigger_rate_buildup_update, on: [:create, :update, :destroy]

  private

  # Auto-populate duration_days based on the purpose and breakdown parameters
  # This only runs on create, so it sets the initial value from the breakdown
  def populate_duration_from_breakdown
    return unless on_site_mobile_crane_breakdown.present?

    self.duration_days = case purpose
                         when 'main'
                           on_site_mobile_crane_breakdown.program_duration_days
                         when 'splicing'
                           on_site_mobile_crane_breakdown.splicing_crane_days
                         when 'misc'
                           on_site_mobile_crane_breakdown.misc_crane_days
                         else
                           0
                         end
  end

  # Calculate wet_rate_per_day from associated crane_rate only when crane_rate_id changes
  # If user manually edits wet_rate_per_day, respect that value
  def calculate_wet_rate_per_day
    return unless crane_rate.present?
    # Only auto-sync if crane_rate_id just changed OR wet_rate_per_day is nil/zero
    if crane_rate_id_changed? || wet_rate_per_day.blank? || wet_rate_per_day.zero?
      self.wet_rate_per_day = crane_rate.wet_rate_per_day
    end
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

  # Verify total_cost was calculated after save; if still 0, recalculate and update
  # This ensures the calculation is correct even if callbacks didn't run in expected order
  def verify_total_cost_calculated
    qty = (quantity || 0).to_f
    days = (duration_days || 0).to_f
    rate = (wet_rate_per_day || 0).to_f
    expected_total = qty * days * rate

    # Only update if total_cost doesn't match the expected calculation
    if total_cost != expected_total
      update_column(:total_cost, expected_total)
    end
  end

  # Trigger parent ProjectRateBuildUp to recalculate crainage_rate when crane selections change
  def trigger_rate_buildup_update
    return unless tender.present?
    
    rate_buildup = tender.project_rate_buildup
    return unless rate_buildup.present?
    
    # Clear cache to ensure fresh calculation
    tender.on_site_mobile_crane_breakdown&.reload
    
    rate_buildup.save!
  end
end
