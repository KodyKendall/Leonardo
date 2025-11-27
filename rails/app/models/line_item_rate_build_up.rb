class LineItemRateBuildUp < ApplicationRecord
  belongs_to :tender_line_item

  before_save :calculate_totals

  private

  def calculate_totals
    # Calculate subtotal by summing only the included components
    self.subtotal = 0
    self.subtotal += material_supply_rate if material_supply_rate.present?
    self.subtotal += fabrication_rate if fabrication_included?
    self.subtotal += overheads_rate if overheads_included?
    self.subtotal += shop_priming_rate if shop_priming_included?
    self.subtotal += onsite_painting_rate if onsite_painting_included?
    self.subtotal += delivery_rate if delivery_included?
    self.subtotal += bolts_rate if bolts_included?
    self.subtotal += erection_rate if erection_included?
    self.subtotal += crainage_rate if crainage_included?
    self.subtotal += cherry_picker_rate if cherry_picker_included?
    self.subtotal += galvanizing_rate if galvanizing_included?

    # Set margin amount (default to 0 if not set)
    self.margin_amount ||= 0

    # Calculate total before rounding
    self.total_before_rounding = subtotal + margin_amount

    # Round to nearest whole number
    self.rounded_rate = total_before_rounding.round
  end
end
