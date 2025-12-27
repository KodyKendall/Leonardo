class TenderSpecificMaterialRate < ApplicationRecord
  # Associations
  belongs_to :tender
  belongs_to :material_supply, optional: true
  has_many :line_item_materials, foreign_key: :material_supply_id, primary_key: :material_supply_id

  # Validations
  validates :tender_id, presence: true
  validates :material_supply_id, presence: true, if: :rate_present_or_notes_present?
  validates :rate, numericality: { greater_than_or_equal_to: 0 }, if: :rate_present?
  validates :tender_id, uniqueness: { scope: :material_supply_id, message: "and material supply combination must be unique" }, unless: :material_supply_id_blank?, if: :material_supply_id_changed?
  validate :effective_dates_valid

  # Callbacks
  after_update :cascade_rate_updates_if_rate_changed
  
  # Log when rate changes
  before_save :log_rate_change

  # Scopes
  scope :active, -> { where("effective_from IS NULL OR effective_from <= ?", Date.current).where("effective_to IS NULL OR effective_to >= ?", Date.current) }

  private

  def log_rate_change
    if rate_changed?
      Rails.logger.info("🪲 RATE_CHANGE: TenderSpecificMaterialRate id=#{id}, rate_was=#{rate_was}, rate=#{rate}")
    end
  end

  def cascade_rate_updates_if_rate_changed
    Rails.logger.info("🪲 CASCADE CALLBACK TRIGGERED: id=#{id}, rate_changed?=#{rate_changed?}")
    # Only cascade if we have a material_supply_id and tender_id
    return unless material_supply_id.present? && tender_id.present?

    Rails.logger.info("🪲 CASCADE: Starting cascade for TenderSpecificMaterialRate id=#{id}, material_supply_id=#{material_supply_id}, tender_id=#{tender_id}, rate_change=#{rate_was} -> #{rate}")

    # Find all LineItemMaterial records that:
    # 1. Reference this material_supply_id
    # 2. Belong to TenderLineItems in this tender
    affected_line_item_materials = LineItemMaterial
      .where(material_supply_id: material_supply_id)
      .joins(:tender_line_item)
      .where(tender_line_items: { tender_id: tender_id })
      .to_a  # Convert to array to keep for later

    # Track counts for broadcasting
    material_count = affected_line_item_materials.count
    Rails.logger.info("🪲 CASCADE: Found #{material_count} affected LineItemMaterials")
    return if material_count.zero?

    # Batch update all affected LineItemMaterial records with new rate
    old_rate = rate_was
    new_rate = rate
    LineItemMaterial.where(id: affected_line_item_materials.map(&:id)).update_all(rate: new_rate)
    Rails.logger.info("🪲 CASCADE: Updated #{material_count} LineItemMaterials to rate=#{new_rate}")

    # Get unique tender_line_item IDs to recalculate their totals
    affected_tender_line_item_ids = affected_line_item_materials.map(&:tender_line_item_id).uniq
    affected_line_item_count = affected_tender_line_item_ids.count
    Rails.logger.info("🪲 CASCADE: Found #{affected_line_item_count} affected TenderLineItems: #{affected_tender_line_item_ids.inspect}")

    # Reload affected materials to get updated rates and trigger breakdown recalculation
    # We save the breakdowns which will trigger LineItemRateBuildUp to recalculate and broadcast
    affected_tender_line_items = TenderLineItem.where(id: affected_tender_line_item_ids)
    
    affected_tender_line_items.each do |tender_line_item|
      breakdown = tender_line_item.line_item_material_breakdown
      if breakdown.present?
        Rails.logger.info("🪲 CASCADE: Saving LineItemMaterialBreakdown id=#{breakdown.id} for TenderLineItem id=#{tender_line_item.id}")
        breakdown.save!
      end
    end

    # Broadcast each affected TenderLineItem to the tender builder to update all frames
    affected_tender_line_items.each do |tender_line_item|
      Rails.logger.info("🪲 CASCADE: Broadcasting TenderLineItem id=#{tender_line_item.id} to tender_#{tender_id}_builder")
      Turbo::StreamsChannel.broadcast_replace_to(
        "tender_#{tender_id}_builder",
        target: ActionView::RecordIdentifier.dom_id(tender_line_item),
        partial: "tender_line_items/tender_line_item",
        locals: { tender_line_item: tender_line_item, open_breakdown: true }
      )
    end

    Rails.logger.info("🪲 CASCADE: Cascade complete for material_supply_id=#{material_supply_id}")
    # Broadcast success message to the tender-specific material rates page
    broadcast_cascade_success(material_count, affected_line_item_count, old_rate, new_rate)
  end

  def broadcast_cascade_success(material_count, line_item_count, old_rate, new_rate)
    broadcast_append_to(
      "tender_#{tender_id}_material_rates",
      target: "cascade_messages",
      partial: "tender_specific_material_rates/cascade_success",
      locals: {
        material_count: material_count,
        line_item_count: line_item_count,
        old_rate: old_rate,
        new_rate: new_rate
      }
    )
  end

  def rate_present?
    rate.present?
  end

  def rate_present_or_notes_present?
    rate.present? || notes.present?
  end

  def material_supply_id_blank?
    material_supply_id.blank?
  end

  def effective_dates_valid
    return if effective_from.blank? || effective_to.blank?

    if effective_to <= effective_from
      errors.add(:effective_to, "must be after effective_from")
    end
  end
end
