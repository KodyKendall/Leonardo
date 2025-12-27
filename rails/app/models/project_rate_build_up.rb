class ProjectRateBuildUp < ApplicationRecord
  include ActionView::RecordIdentifier
  
  belongs_to :tender

  # Validations
  validates :tender_id, presence: true, uniqueness: true
  validates :material_supply_rate, :fabrication_rate, :overheads_rate, 
            :shop_priming_rate, :onsite_painting_rate, :delivery_rate,
            :bolts_rate, :erection_rate, :crainage_rate, :cherry_picker_rate,
            :galvanizing_rate, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  # Callbacks
  after_update_commit :broadcast_update

  # Broadcasts update to tender builder channel
  private

  def broadcast_update
    broadcast_update_to(
      "tender_#{tender_id}_builder",
      target: dom_id(self),
      partial: "project_rate_build_ups/project_rate_build_up",
      locals: { project_rate_build_up: self }
    )
  end
end
