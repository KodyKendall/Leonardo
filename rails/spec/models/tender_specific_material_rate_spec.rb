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

    it 'auto-sets material_supply_type to MaterialSupply' do
      rate = TenderSpecificMaterialRate.new(
        tender: tender,
        material_supply_id: material_supply.id
      )
      rate.valid?
      expect(rate.material_supply_type).to eq('MaterialSupply')
    end

    it 'prevents duplicates for the same tender and material_supply' do
      TenderSpecificMaterialRate.create!(
        tender: tender,
        material_supply: material_supply,
        rate: 100.0
      )
      
      duplicate = TenderSpecificMaterialRate.new(
        tender: tender,
        material_supply: material_supply,
        rate: 200.0
      )
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:tender_id]).to include("and material supply combination must be unique")
    end
  end
end
