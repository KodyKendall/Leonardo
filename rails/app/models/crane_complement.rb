class CraneComplement < ApplicationRecord
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
end
