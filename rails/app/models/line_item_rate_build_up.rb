class LineItemRateBuildUp < ApplicationRecord
  belongs_to :tender_line_item

  validates :margin_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  
  # All inclusion fields are now decimal multipliers (0.01 to 5.0)
  # Validate only if value is present and not zero (zero gets normalized to 1.0)
  %i[material_supply_included fabrication_included overheads_included shop_priming_included 
     onsite_painting_included delivery_included bolts_included erection_included 
     crainage_included cherry_picker_included galvanizing_included].each do |field|
    validates field, numericality: { greater_than_or_equal_to: 0.01, less_than_or_equal_to: 5.0 }, 
                    if: -> { send(field).present? && send(field) != 0 }
  end

  before_save :normalize_multipliers
  before_save :calculate_totals
  after_save :sync_rate_to_tender_line_item
  after_save :update_tender_grand_total

  private

  def normalize_multipliers
    # Convert empty/zero multiplier values to 1.0 (default)
    %i[material_supply_included fabrication_included overheads_included shop_priming_included 
       onsite_painting_included delivery_included bolts_included erection_included 
       crainage_included cherry_picker_included galvanizing_included].each do |field|
      value = send(field)
      if value.nil? || value.zero?
        send("#{field}=", 1.0)
      end
    end
  end

  def update_tender_grand_total
    tender_line_item.tender.recalculate_grand_total!
  end

  def calculate_totals
    # Calculate subtotal by summing all components with their multipliers
    self.subtotal = 0
    
    # All components now use decimal multipliers (default to 0 if nil/not set)
    self.subtotal += (material_supply_rate * (material_supply_included || 0).to_f)
    self.subtotal += (fabrication_rate * (fabrication_included || 0).to_f)
    self.subtotal += (overheads_rate * (overheads_included || 0).to_f)
    self.subtotal += (shop_priming_rate * (shop_priming_included || 0).to_f)
    self.subtotal += (onsite_painting_rate * (onsite_painting_included || 0).to_f)
    self.subtotal += (delivery_rate * (delivery_included || 0).to_f)
    self.subtotal += (bolts_rate * (bolts_included || 0).to_f)
    self.subtotal += (erection_rate * (erection_included || 0).to_f)
    self.subtotal += (crainage_rate * (crainage_included || 0).to_f)
    self.subtotal += (cherry_picker_rate * (cherry_picker_included || 0).to_f)
    self.subtotal += (galvanizing_rate * (galvanizing_included || 0).to_f)

    # Set margin percentage (default to 0 if not set)
    self.margin_percentage ||= 0

    # Calculate total before rounding: subtotal * (1 + margin_percentage / 100)
    self.total_before_rounding = subtotal * (1 + margin_percentage / 100.0)

    # Round to nearest whole number
    self.rounded_rate = total_before_rounding.round
  end

  def sync_rate_to_tender_line_item
    return if rounded_rate.nil?
    tender_line_item.update_column(:rate, rounded_rate)
  end
end
