class PopulateTenderMaterialRates
  def initialize(tender)
    @tender = tender
  end

  def execute
    created_rates = []

    # Iterate over ALL MaterialSupply items (all 23)
    # Create a TenderSpecificMaterialRate for each, regardless of whether a rate exists
    MaterialSupply.find_each do |material_supply|
      # Try to find the best rate from the current active window
      rate_value = find_best_rate_for_material(material_supply)
      
      # If rate_value is nil, that's OK - we'll create the record with null rate
      begin
        # Create the TenderSpecificMaterialRate
        # rate can be nil if no active monthly rate or no supplier rates exist
        tender_rate = @tender.tender_specific_material_rates.create(
          material_supply_id: material_supply.id,
          rate: rate_value,
          unit: nil,
          effective_from: nil,
          effective_to: nil,
          notes: nil
        )

        if tender_rate.persisted?
          created_rates << tender_rate
          rate_display = rate_value ? "#{rate_value}" : "nil (to be filled)"
          Rails.logger.info("Created TenderSpecificMaterialRate for tender #{@tender.id}, material #{material_supply.id} (#{material_supply.name}), rate #{rate_display}")
        else
          Rails.logger.warn("Failed to create rate for material #{material_supply.id}: #{tender_rate.errors.full_messages.join(', ')}")
        end
      rescue ActiveRecord::RecordNotUnique
        # Unique constraint violation (duplicate tender_id + material_supply_id) - silently skip
        Rails.logger.warn("Duplicate rate already exists for tender #{@tender.id}, material #{material_supply.id}")
      rescue => e
        Rails.logger.error("Unexpected error creating rate for material #{material_supply.id}: #{e.message}")
      end
    end

    Rails.logger.info("Auto-population complete: created #{created_rates.count} rates for tender #{@tender.id}")
    created_rates
  end

  private

  # Find the best rate for a given material
  # First looks for the current active MonthlyMaterialSupplyRate window
  # Within that window:
  #   Priority 1: Winner rate (is_winner = true)
  #   Priority 2: Cheapest rate (lowest rate value)
  # Returns nil if no active window exists or no rate found for this material
  def find_best_rate_for_material(material_supply)
    # Find the current active MonthlyMaterialSupplyRate
    current_monthly_rate = MonthlyMaterialSupplyRate
      .where("effective_from <= ?", Date.current)
      .where("effective_to >= ?", Date.current)
      .order(effective_from: :desc)
      .first

    # If no active window, return nil (rate will be null in the created record)
    return nil unless current_monthly_rate

    # Priority 1: Find winner rate
    winner_rate = MaterialSupplyRate
      .where(monthly_material_supply_rate_id: current_monthly_rate.id, material_supply_id: material_supply.id, is_winner: true)
      .first

    return winner_rate.rate if winner_rate

    # Priority 2: Find cheapest rate
    cheapest_rate = MaterialSupplyRate
      .where(monthly_material_supply_rate_id: current_monthly_rate.id, material_supply_id: material_supply.id)
      .order(rate: :asc)
      .first

    return cheapest_rate.rate if cheapest_rate

    # No rate found in active window - return nil
    nil
  end
end
