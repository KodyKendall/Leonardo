class CraneComplement < ApplicationRecord
  before_save :calculate_default_wet_rate

  # Calculate the actual wet rate for a given breakdown by looking up the crane rate
  # Parses the primary crane size from crane_recommendation (e.g., "25t" from "1 × 25t")
  # and fetches the rate from CraneRate table filtered by ownership_type
  def calculated_wet_rate_for(breakdown)
    return 0.0 unless breakdown.present? && crane_recommendation.present?
    
    # Extract the first crane size from crane_recommendation using regex
    # Looks for pattern like "25t" or "1 × 25t"
    size_match = crane_recommendation.match(/(\d+)t/)
    return 0.0 unless size_match
    
    crane_size = "#{size_match[1]}t"
    
    # Look up the crane rate by size, ownership type, and active status
    crane_rate = CraneRate.find_by(
      size: crane_size,
      ownership_type: breakdown.ownership_type,
      is_active: true
    )
    
    crane_rate&.wet_rate_per_day || 0.0
  end

  private

  # Auto-calculate default_wet_rate_per_day based on crane_recommendation
  # Parses all cranes from the recommendation string (e.g., "2 × 10t + 1 × 25t + 2 × 35t")
  # and sums their rental wet rates: (qty1 × rate1) + (qty2 × rate2) + ...
  def calculate_default_wet_rate
    return unless crane_recommendation.present?

    # Parse crane_recommendation to extract all (quantity, size) pairs
    # Pattern: "2 × 10t" or "2 x 10t" (case-insensitive × or x)
    pattern = /(\d+)\s*[×x]\s*(\d+)t/i
    matches = crane_recommendation.scan(pattern)

    return if matches.empty?

    # Sum the weighted rates for all cranes
    total_rate = 0.0
    matches.each do |quantity_str, size_str|
      quantity = quantity_str.to_i
      size = "#{size_str}t"

      # Look up the active rental crane rate for this size
      crane_rate = CraneRate.find_by(
        size: size,
        ownership_type: 'rental',
        is_active: true
      )

      # Only add to total if rate exists (graceful degradation)
      total_rate += (quantity * crane_rate.wet_rate_per_day) if crane_rate.present?
    end

    self.default_wet_rate_per_day = total_rate
  end
end
