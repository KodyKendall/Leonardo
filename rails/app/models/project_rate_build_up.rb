class ProjectRateBuildUp < ApplicationRecord
  include ActionView::RecordIdentifier
  
  belongs_to :tender

  # Validations
  validates :tender_id, presence: true, uniqueness: true
  validates :material_supply_rate, :fabrication_rate, :overheads_rate, 
            :shop_priming_rate, :onsite_painting_rate, :delivery_rate,
            :bolts_rate, :erection_rate, :crainage_rate, :cherry_picker_rate,
            :galvanizing_rate, :shop_drawings_rate, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  # Callbacks
  before_save :calculate_crainage_rate
  after_update_commit :broadcast_update

  # Calculates crainage_rate from crane selections and tender tonnage
  def calculate_crainage_rate
    return if tender.blank?
    
    crane_breakdown = tender.on_site_mobile_crane_breakdown
    self.crainage_rate = crane_breakdown&.crainage_rate_per_tonne || 0
  end

  # Broadcasts update to tender builder channel
  private

  def broadcast_update
    broadcast_update_to(
      "tender_#{tender_id}_builder",
      target: dom_id(self),
      partial: "project_rate_build_ups/project_rate_build_up",
      locals: { project_rate_build_up: self }
    )
    # Also broadcast shop drawings update to the builder page
    broadcast_shop_drawings_update
  end

  def broadcast_shop_drawings_update
    broadcast_update_to(
      "tender_#{tender_id}_builder",
      target: "tender_#{tender_id}_shop_drawings",
      partial: "tenders/shop_drawings",
      locals: { tender: tender }
    )
  end
end
