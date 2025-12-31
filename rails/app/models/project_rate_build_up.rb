class ProjectRateBuildUp < ApplicationRecord
  include ActionView::RecordIdentifier
  
  belongs_to :tender

  # Validations
  validates :tender_id, presence: true, uniqueness: true
  validates :profit_margin_percentage, :material_supply_rate, :fabrication_rate, :overheads_rate, 
            :shop_priming_rate, :onsite_painting_rate, :delivery_rate,
            :bolts_rate, :erection_rate, :crainage_rate, :cherry_picker_rate,
            :galvanizing_rate, :shop_drawings_rate, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  # Callbacks
  before_save :calculate_crainage_rate
  after_update_commit :sync_rates_to_child_line_items
  after_update_commit :broadcast_update

  # Calculates crainage_rate from crane selections and tender tonnage
  def calculate_crainage_rate
    return if tender.blank?
    
    crane_breakdown = tender.on_site_mobile_crane_breakdown
    self.crainage_rate = crane_breakdown&.crainage_rate_per_tonne || 0
  end

  # Syncs changed rates to child line item rate buildups if they haven't been overridden
  def sync_rates_to_child_line_items
    inherited_categories = [
      :fabrication, :overheads, :shop_priming, :onsite_painting,
      :delivery, :bolts, :erection, :galvanizing
    ]

    # Identify which inherited rates actually changed
    changes = saved_changes.slice(*inherited_categories.map { |cat| "#{cat}_rate" })
    return if changes.empty?

    tender.tender_line_items.includes(:line_item_rate_build_up).find_each do |line_item|
      rate_buildup = line_item.line_item_rate_build_up
      next unless rate_buildup

      should_save = false
      changes.each do |rate_attr, (old_val, new_val)|
        # Aggressive Sync: Project rates act as the master source of truth.
        # This overrides any manual edits previously made at the line item level.
        rate_buildup.send("#{rate_attr}=", new_val)
        should_save = true
      end

      # Saving triggers LineItemRateBuildUp's own calculation and broadcast chain
      rate_buildup.save! if should_save
    end
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
