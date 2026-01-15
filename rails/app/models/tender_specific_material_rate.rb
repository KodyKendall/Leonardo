class TenderSpecificMaterialRate < ApplicationRecord
  # Associations
  belongs_to :tender
  belongs_to :material_supply, polymorphic: true, optional: true
  belongs_to :supplier, optional: true
  
  def line_item_materials
    LineItemMaterial.where(material_supply_id: material_supply_id, material_supply_type: material_supply_type)
                    .joins(:tender_line_item)
                    .where(tender_line_items: { tender_id: tender_id })
  end

  # Validations
  validates :tender_id, presence: true
  validates :material_supply_id, presence: true, if: :rate_present_or_notes_present?
  validates :rate, numericality: { greater_than_or_equal_to: 0 }, if: :rate_present?
  validates :tender_id, uniqueness: { scope: [:material_supply_id, :material_supply_type], message: "and material supply combination must be unique" }, unless: :material_supply_id_blank?, if: -> { material_supply_id_changed? || material_supply_type_changed? }

  # Callbacks
  after_update :cascade_rate_updates_if_rate_changed
  
  # Virtual attribute to skip broadcasts during bulk operations
  attr_accessor :skip_broadcast

  # Log when rate changes
  before_save :log_rate_change

  private

  def log_rate_change
    if rate_changed?
      Rails.logger.info("🪲 RATE_CHANGE: TenderSpecificMaterialRate id=#{id}, rate_was=#{rate_was}, rate=#{rate}")
    end
  end

  def cascade_rate_updates_if_rate_changed
    return unless rate_previously_changed? # Use rate_previously_changed? for after_update
    Rails.logger.info("🪲 CASCADE CALLBACK TRIGGERED: id=#{id}")
    # Only cascade if we have a material_supply_id and tender_id
    return unless material_supply_id.present? && tender_id.present?

    Rails.logger.info("🪲 CASCADE: Starting cascade for TenderSpecificMaterialRate id=#{id}, material_supply_id=#{material_supply_id}, tender_id=#{tender_id}")

    # Find all LineItemMaterial records that:
    # 1. Reference this material_supply_id and material_supply_type
    # 2. Belong to TenderLineItems in this tender
    affected_line_item_materials = LineItemMaterial
      .where(material_supply_id: material_supply_id, material_supply_type: material_supply_type)
      .joins(:tender_line_item)
      .where(tender_line_items: { tender_id: tender_id })
      .to_a

    material_count = affected_line_item_materials.count
    return if material_count.zero?

    # Batch update all affected LineItemMaterial records with new rate
    old_rate = rate_previously_was(:rate)
    new_rate = rate
    LineItemMaterial.where(id: affected_line_item_materials.map(&:id)).update_all(rate: new_rate)

    # Get unique tender_line_item IDs to recalculate their totals
    affected_tender_line_item_ids = affected_line_item_materials.map(&:tender_line_item_id).uniq
    affected_line_item_count = affected_tender_line_item_ids.count

    # Reload affected materials to get updated rates and trigger breakdown recalculation
    affected_tender_line_items = TenderLineItem.where(id: affected_tender_line_item_ids)
    
    affected_tender_line_items.each do |tender_line_item|
      breakdown = tender_line_item.line_item_material_breakdown
      if breakdown.present?
        breakdown.save!
      end
    end

    # Skip broadcasts if requested (e.g. during bulk population)
    return if skip_broadcast

    # Broadcast each affected TenderLineItem to the tender builder
    affected_tender_line_items.each do |tender_line_item|
      Turbo::StreamsChannel.broadcast_replace_to(
        "tender_#{tender_id}_builder",
        target: ActionView::RecordIdentifier.dom_id(tender_line_item),
        partial: "tender_line_items/tender_line_item",
        locals: { tender_line_item: tender_line_item, open_breakdown: true }
      )
    end

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
end
