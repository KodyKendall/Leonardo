require 'rails_helper'

RSpec.describe PreliminariesGeneralItem, type: :model do
  let(:tender) { create(:tender, total_tonnage: 100) }
  let!(:crane_breakdown) { create(:on_site_mobile_crane_breakdown, tender: tender) }
  let!(:equipment_summary) { create(:tender_equipment_summary, tender: tender) }

  before do
    # Stub crainage_rate_per_tonne and cherry_picker_rate_per_tonne for easy testing
    allow_any_instance_of(OnSiteMobileCraneBreakdown).to receive(:crainage_rate_per_tonne).and_return(2000.0)
    allow_any_instance_of(TenderEquipmentSummary).to receive(:cherry_picker_rate_per_tonne).and_return(1500.0)
  end

  describe "automatic rate syncing" do
    context "when is_crane is true" do
      it "pulls the rate from the crane breakdown on save" do
        item = create(:preliminaries_general_item, tender: tender, is_crane: true, category: 'fixed_based', description: 'Crane Item', rate: 0)
        expect(item.rate).to eq(2000.0)
      end

      it "updates the rate on subsequent saves" do
        item = create(:preliminaries_general_item, tender: tender, is_crane: true, category: 'fixed_based', description: 'Crane Item')
        
        allow_any_instance_of(OnSiteMobileCraneBreakdown).to receive(:crainage_rate_per_tonne).and_return(2500.0)
        item.save!
        expect(item.reload.rate).to eq(2500.0)
      end
    end

    context "when is_access_equipment is true" do
      it "pulls the rate from the equipment summary on save" do
        item = create(:preliminaries_general_item, tender: tender, is_access_equipment: true, category: 'fixed_based', description: 'Access Item', rate: 0)
        expect(item.rate).to eq(1500.0)
      end

      it "updates the rate on subsequent saves" do
        item = create(:preliminaries_general_item, tender: tender, is_access_equipment: true, category: 'fixed_based', description: 'Access Item')
        
        allow_any_instance_of(TenderEquipmentSummary).to receive(:cherry_picker_rate_per_tonne).and_return(1800.0)
        item.save!
        expect(item.reload.rate).to eq(1800.0)
      end
    end
  end
end
