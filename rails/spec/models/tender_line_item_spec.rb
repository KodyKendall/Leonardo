require 'rails_helper'

RSpec.describe TenderLineItem, type: :model do
  describe 'inheritance from project rate buildup' do
    let(:tender) { create(:tender) }
    let!(:project_rate_buildup) do
      tender.reload.project_rate_buildup.update!(
        material_supply_rate: 1000,
        fabrication_rate: 500,
        shop_drawings_rate: 100
      )
      tender.project_rate_buildup
    end

    it 'populates rates and recalculates buildup on creation' do
      line_item = create(:tender_line_item, tender: tender)
      rate_buildup = line_item.line_item_rate_build_up

      expect(rate_buildup.material_supply_rate).to eq(1000)
      expect(rate_buildup.fabrication_rate).to eq(500)
      expect(rate_buildup.shop_drawings_rate).to eq(100)
      
      # Subtotal: 1000 (material) + 500 (fab) + 100 (shop drawings) = 1600
      # (Assuming default inclusions are 1.0 for fab and shop drawings)
      expect(rate_buildup.subtotal).to eq(1600)
      expect(rate_buildup.rounded_rate).to eq(1600)
    end
  end
end
