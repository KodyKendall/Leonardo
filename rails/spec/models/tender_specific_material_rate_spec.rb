require 'rails_helper'

RSpec.describe TenderSpecificMaterialRate, type: :model do
  describe 'associations' do
    it { should belong_to(:tender) }
    it { should belong_to(:material_supply).optional }
    it { should belong_to(:supplier).optional }
  end

  describe 'persistence' do
    let(:tender) { Tender.create!(tender_name: 'Test Tender', status: 'Draft') }
    let(:material_supply) { MaterialSupply.create!(name: 'Steel', waste_percentage: 5.0) }
    let(:supplier) { Supplier.create!(name: 'Acme Steel') }
    
    it 'correctly persists supplier_id' do
      rate = TenderSpecificMaterialRate.create!(
        tender: tender,
        material_supply: material_supply,
        rate: 100.0,
        supplier: supplier
      )
      
      expect(rate.reload.supplier_id).to eq(supplier.id)
      expect(rate.supplier.name).to eq('Acme Steel')
    end

    it 'allows supplier to be nil' do
      rate = TenderSpecificMaterialRate.create!(
        tender: tender,
        material_supply: material_supply,
        rate: 100.0,
        supplier: nil
      )
      
      expect(rate.reload.supplier_id).to be_nil
    end
  end
end
