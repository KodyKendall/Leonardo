class PopulateTenderMaterialRates
  def initialize(tender, monthly_material_supply_rate: nil)
    @tender = tender
    @monthly_material_supply_rate = monthly_material_supply_rate
  end

  def execute
    updated_rates = []

    # Iterate over ALL MaterialSupply items
    # Create or update a TenderSpecificMaterialRate for each
    MaterialSupply.find_each do |material_supply|
      # Try to find the best rate from the selected or current monthly rate
      best_rate_record = find_best_rate_record_for_material(material_supply)
      rate_value = best_rate_record&.rate
      supplier_id = best_rate_record&.supplier_id
      
      begin
        # Find or initialize the TenderSpecificMaterialRate
        # Must include material_supply_type for polymorphic association to work correctly
        tender_rate = @tender.tender_specific_material_rates.find_or_initialize_by(
          material_supply_id: material_supply.id,
          material_supply_type: 'MaterialSupply'
        )

        tender_rate.assign_attributes(
          rate: rate_value,
          supplier_id: supplier_id,
          unit: "tonne", # Default to tonne as per MaterialSupplyRate validation
          skip_broadcast: true
        )

        if tender_rate.save
          updated_rates << tender_rate
          rate_display = rate_value ? "#{rate_value}" : "nil"
          Rails.logger.info("🪲 Populated TenderSpecificMaterialRate for tender #{@tender.id}, material #{material_supply.id}, rate #{rate_display}")
        else
          Rails.logger.warn("Failed to save rate for material #{material_supply.id}: #{tender_rate.errors.full_messages.join(', ')}")
        end
      rescue => e
        Rails.logger.error("Unexpected error populating rate for material #{material_supply.id}: #{e.message}")
      end
    end

    # After bulk update, trigger a single recalculation of tender totals
    @tender.recalculate_grand_total!
    
    Rails.logger.info("Auto-population complete: processed #{updated_rates.count} rates for tender #{@tender.id}")
    updated_rates
  end

  private

  # Find the best rate record for a given material
  # Priority 1: Winner rate (is_winner = true)
  # Priority 2: Cheapest rate (lowest rate value)
  def find_best_rate_record_for_material(material_supply)
    target_monthly_rate = @monthly_material_supply_rate || current_active_monthly_rate

    # If no active window, return nil
    return nil unless target_monthly_rate

    # Priority 1: Find winner rate
    winner_rate = MaterialSupplyRate
      .where(monthly_material_supply_rate_id: target_monthly_rate.id, material_supply_id: material_supply.id, is_winner: true)
      .first

    return winner_rate if winner_rate

    # Priority 2: Find cheapest rate
    cheapest_rate = MaterialSupplyRate
      .where(monthly_material_supply_rate_id: target_monthly_rate.id, material_supply_id: material_supply.id)
      .order(rate: :asc)
      .first

    return cheapest_rate if cheapest_rate

    nil
  end

  def current_active_monthly_rate
    MonthlyMaterialSupplyRate
      .where("effective_from <= ?", Date.current)
      .where("effective_to >= ?", Date.current)
      .order(effective_from: :desc)
      .first
  end
end
