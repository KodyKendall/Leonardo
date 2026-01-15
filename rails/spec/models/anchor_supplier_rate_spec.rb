require 'rails_helper'

RSpec.describe AnchorSupplierRate, type: :model do
  describe "associations" do
    it { should belong_to(:anchor_rate) }
    it { should belong_to(:supplier) }
  end

  describe "validations" do
    it { should validate_presence_of(:rate) }
    it { should validate_numericality_of(:rate).is_greater_than_or_equal_to(0) }
    
    it "validates uniqueness of supplier_id scoped to anchor_rate_id" do
      anchor_rate = AnchorRate.create!(name: "Test Anchor", material_cost: 10)
      supplier = Supplier.create!(name: "Test Supplier")
      AnchorSupplierRate.create!(anchor_rate: anchor_rate, supplier: supplier, rate: 10)
      
      duplicate = AnchorSupplierRate.new(anchor_rate: anchor_rate, supplier: supplier, rate: 20)
      expect(duplicate).not_to be_valid
    end
  end

  describe "callbacks" do
    let(:anchor_rate) { AnchorRate.create!(name: "Anchor 1", material_cost: 0) }
    let(:supplier_hilti) { Supplier.create!(name: "Hilti") }
    let(:supplier_ika) { Supplier.create!(name: "IKA") }

    describe "#clear_other_winners" do
      it "ensures only one winner per anchor rate" do
        rate1 = AnchorSupplierRate.create!(anchor_rate: anchor_rate, supplier: supplier_hilti, rate: 100, is_winner: true)
        rate2 = AnchorSupplierRate.create!(anchor_rate: anchor_rate, supplier: supplier_ika, rate: 110, is_winner: false)

        expect(rate1.reload.is_winner).to be true
        
        rate2.update!(is_winner: true)
        
        expect(rate1.reload.is_winner).to be false
        expect(rate2.reload.is_winner).to be true
      end
    end

    describe "#sync_to_anchor_rate" do
      it "updates the parent anchor_rate material_cost when marked as winner" do
        rate = AnchorSupplierRate.create!(anchor_rate: anchor_rate, supplier: supplier_hilti, rate: 150, is_winner: true)
        
        expect(anchor_rate.reload.material_cost).to eq(150)
      end

      it "does not update the parent anchor_rate material_cost when not a winner" do
        anchor_rate.update!(material_cost: 500)
        rate = AnchorSupplierRate.create!(anchor_rate: anchor_rate, supplier: supplier_hilti, rate: 150, is_winner: false)
        
        expect(anchor_rate.reload.material_cost).to eq(500)
      end
    end

    describe "#reset_anchor_rate_cost" do
      it "resets the parent anchor_rate material_cost to 0 when the winner is destroyed" do
        rate = AnchorSupplierRate.create!(anchor_rate: anchor_rate, supplier: supplier_hilti, rate: 150, is_winner: true)
        expect(anchor_rate.reload.material_cost).to eq(150)
        
        rate.destroy!
        expect(anchor_rate.reload.material_cost).to eq(0)
      end

      it "does not reset the cost if a non-winner is destroyed" do
        rate1 = AnchorSupplierRate.create!(anchor_rate: anchor_rate, supplier: supplier_hilti, rate: 150, is_winner: true)
        rate2 = AnchorSupplierRate.create!(anchor_rate: anchor_rate, supplier: supplier_ika, rate: 200, is_winner: false)
        
        rate2.destroy!
        expect(anchor_rate.reload.material_cost).to eq(150)
      end
    end
  end
end
