class LineItemRateBuildUp < ApplicationRecord
  belongs_to :tender_line_item
  has_many :rate_buildup_custom_items, dependent: :destroy

  accepts_nested_attributes_for :rate_buildup_custom_items, allow_destroy: true

  validates :margin_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :rounding_interval, inclusion: { in: [0, 10, 20, 50, 100] }
  
  # All inclusion fields are now decimal multipliers (0.01 and above)
  # Validate only if value is present and not zero (zero gets normalized to 1.0)
  %i[material_supply_included fabrication_included overheads_included shop_priming_included 
     onsite_painting_included delivery_included bolts_included erection_included 
     crainage_included cherry_picker_included galvanizing_included].each do |field|
    validates field, numericality: { greater_than_or_equal_to: 0.01 }, 
                    if: -> { send(field).present? && send(field) != 0 }
  end

  before_save :normalize_multipliers
  before_save :calculate_totals
  after_save :sync_rate_to_tender_line_item
  after_commit :broadcast_to_tender_line_item
  after_save :update_tender_grand_total

  # PUBLIC METHODS
  
  def recalculate_totals!
    calculate_totals
    update_columns(
      subtotal: subtotal,
      total_before_rounding: total_before_rounding,
      rounded_rate: rounded_rate
    )
    sync_rate_to_tender_line_item
  end

  def broadcast_to_self
    broadcast_replace_to(
      ActionView::RecordIdentifier.dom_id(self),
      partial: "line_item_rate_build_ups/line_item_rate_build_up",
      locals: { line_item_rate_build_up: self }
    )
  end

  private

  def normalize_multipliers
    # Convert nil multiplier values to 1.0 (default)
    # DO NOT convert 0.0 to 1.0 — 0.0 means "excluded" and must be preserved
    %i[material_supply_included fabrication_included overheads_included shop_priming_included 
       onsite_painting_included delivery_included bolts_included erection_included 
       crainage_included cherry_picker_included galvanizing_included].each do |field|
      value = send(field)
      if value.nil?
        send("#{field}=", 1.0)
      end
    end
  end

  def update_tender_grand_total
    tender_line_item.tender.recalculate_grand_total!
  end

  def calculate_totals
    # Calculate subtotal by summing all components with their multipliers
    # Material supply rate is multiplied by its inclusion/multiplier
    self.subtotal = (material_supply_rate || 0).to_f * (material_supply_included || 0).to_f
    
    # All components now use decimal multipliers (default to 0 if nil/not set)
    # Add all other cost components with their multipliers
    self.subtotal += ((fabrication_rate || 0).to_f * (fabrication_included || 0).to_f)
    self.subtotal += ((overheads_rate || 0).to_f * (overheads_included || 0).to_f)
    self.subtotal += ((shop_priming_rate || 0).to_f * (shop_priming_included || 0).to_f)
    self.subtotal += ((onsite_painting_rate || 0).to_f * (onsite_painting_included || 0).to_f)
    self.subtotal += ((delivery_rate || 0).to_f * (delivery_included || 0).to_f)
    self.subtotal += ((bolts_rate || 0).to_f * (bolts_included || 0).to_f)
    self.subtotal += ((erection_rate || 0).to_f * (erection_included || 0).to_f)
    self.subtotal += ((crainage_rate || 0).to_f * (crainage_included || 0).to_f)
    self.subtotal += ((cherry_picker_rate || 0).to_f * (cherry_picker_included || 0).to_f)
    self.subtotal += ((galvanizing_rate || 0).to_f * (galvanizing_included || 0).to_f)

    # Add custom items to subtotal
    # Use reject(&:marked_for_destruction?) to ensure totals are correct when items are deleted via nested attributes
    rate_buildup_custom_items.reject(&:marked_for_destruction?).each do |item|
      self.subtotal += (item.rate || 0).to_f * (item.included || 1.0).to_f
    end

    # Apply Mass Calc multiplier (defaults to 1.0)
    self.mass_calc ||= 1.0
    effective_subtotal = subtotal * mass_calc.to_f

    # Set margin percentage (default to 0 if not set)
    self.margin_percentage ||= 0

    # Calculate total before rounding using the effective subtotal
    self.total_before_rounding = effective_subtotal * (1 + margin_percentage / 100.0)

    # Round UP to nearest interval (10, 20, 50, 100) or keep as is if interval is 0
    interval = (rounding_interval || 50).to_f
    if interval > 0
      self.rounded_rate = (total_before_rounding / interval).ceil * interval
    else
      self.rounded_rate = total_before_rounding
    end
  end

  def sync_rate_to_tender_line_item
    return if rounded_rate.nil?
    tender_line_item.update_column(:rate, rounded_rate)
  end

  def broadcast_to_tender_line_item
    return unless tender_line_item.present?
    
    # Broadcast update to the tender builder stream so other users see the rate update
    broadcast_replace_to(
      "tender_#{tender_line_item.tender_id}_builder",
      target: ActionView::RecordIdentifier.dom_id(tender_line_item),
      partial: "tender_line_items/tender_line_item",
      locals: { tender_line_item: tender_line_item, open_breakdown: true }
    )
  end
end
