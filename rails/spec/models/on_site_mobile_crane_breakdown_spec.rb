require 'rails_helper'

RSpec.describe OnSiteMobileCraneBreakdown, type: :model do
  let(:tender) { create(:tender, total_tonnage: 100) }
  let!(:breakdown) { create(:on_site_mobile_crane_breakdown, tender: tender) }
  let!(:crane_item) { create(:preliminaries_general_item, tender: tender, is_crane: true, category: 'fixed_based', description: 'Crane Item') }
  let!(:other_item) { create(:preliminaries_general_item, tender: tender, is_crane: false, category: 'fixed_based', description: 'Other Item', rate: 100) }

  describe "P&G sync callback" do
    it "triggers a rate update on associated crane P&G items when updated" do
      # Initial state
      allow_any_instance_of(OnSiteMobileCraneBreakdown).to receive(:crainage_rate_per_tonne).and_return(2000.0)
      crane_item.save!
      expect(crane_item.reload.rate).to eq(2000.0)

      # Update breakdown
      allow_any_instance_of(OnSiteMobileCraneBreakdown).to receive(:crainage_rate_per_tonne).and_return(3000.0)
      
      # We need to trigger a save that calls after_update_commit
      breakdown.update!(total_roof_area_sqm: breakdown.total_roof_area_sqm + 1)
      
      expect(crane_item.reload.rate).to eq(3000.0)
      expect(other_item.reload.rate).to eq(100.0)
    end
  end
end
