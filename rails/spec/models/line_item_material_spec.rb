require 'rails_helper'

RSpec.describe LineItemMaterial, type: :model do
  describe "associations" do
    it "can belong to a MaterialSupply" do
      material_supply = MaterialSupply.create!(name: "Test Material", waste_percentage: 10)
      line_item_material = LineItemMaterial.new(material_supply: material_supply)
      expect(line_item_material.material_supply).to eq(material_supply)
      expect(line_item_material.material_supply_type).to eq("MaterialSupply")
    end

    it "can belong to an AnchorRate" do
      anchor_rate = AnchorRate.create!(name: "Test Anchor", waste_percentage: 5, material_cost: 100)
      line_item_material = LineItemMaterial.new(material_supply: anchor_rate)
      expect(line_item_material.material_supply).to eq(anchor_rate)
      expect(line_item_material.material_supply_type).to eq("AnchorRate")
    end

    it "can belong to a NutBoltWasherRate" do
      bolt_rate = NutBoltWasherRate.create!(name: "Test Bolt", waste_percentage: 5, material_cost: 50)
      line_item_material = LineItemMaterial.new(material_supply: bolt_rate)
      expect(line_item_material.material_supply).to eq(bolt_rate)
      expect(line_item_material.material_supply_type).to eq("NutBoltWasherRate")
    end
  end

  describe "callbacks" do
    let(:section_category) { SectionCategory.create!(name: "Test Category", display_name: "Test Category") }
    let(:tender) { Tender.create!(tender_name: "Test Tender", status: "Draft") }
    let(:tender_line_item) { TenderLineItem.create!(tender: tender, quantity: 1, rate: 0, section_category: section_category) }
    let(:line_item_material_breakdown) { tender_line_item.line_item_material_breakdown }
    let(:rate_buildup) { tender_line_item.line_item_rate_build_up }

    it "syncs material supply rate to buildup after save" do
      # Ensure associations are loaded
      line_item_material_breakdown
      rate_buildup
      
      line_item_material = LineItemMaterial.new(
        line_item_material_breakdown: line_item_material_breakdown,
        rate: 100,
        proportion_percentage: 100,
        waste_percentage: 0
      )
      
      expect {
        line_item_material.save!
      }.to change { rate_buildup.reload.material_supply_rate.to_f }.from(0.0).to(100.0)
    end
  end

  describe "calculations and validations" do
    let(:section_category) { SectionCategory.create!(name: "Steel", display_name: "Steel", supply_rates_type: :material_supply_rates) }
    let(:bolt_category) { SectionCategory.create!(name: "Bolts", display_name: "Bolts", supply_rates_type: :nuts_bolts_and_washer_supply_rates) }
    let(:tender) { Tender.create!(tender_name: "Test Tender", e_number: "E123", status: "Draft") }
    let(:tender_line_item) { TenderLineItem.create!(tender: tender, quantity: 1, rate: 0, section_category: section_category) }
    let(:bolt_line_item) { TenderLineItem.create!(tender: tender, quantity: 1, rate: 0, section_category: bolt_category) }
    
    describe "#line_total" do
      it "calculates total as a percentage for standard materials" do
        material = LineItemMaterial.new(
          line_item_material_breakdown: tender_line_item.line_item_material_breakdown,
          rate: 100,
          proportion_percentage: 50, # 50%
          waste_percentage: 10 # 10% waste
        )
        # 100 * (1 + 0.1) * 0.5 = 110 * 0.5 = 55
        expect(material.line_total).to eq(55.0)
      end

      it "calculates total as a quantity multiplier for bolts" do
        material = LineItemMaterial.new(
          line_item_material_breakdown: bolt_line_item.line_item_material_breakdown,
          rate: 100,
          proportion_percentage: 10, # 10 units
          waste_percentage: 10 # 10% waste
        )
        # 100 * (1 + 0.1) * 10 = 110 * 10 = 1100
        expect(material.line_total).to eq(1100.0)
      end
    end

    describe "validations" do
      it "restricts proportion_percentage to 100 for standard materials" do
        material = LineItemMaterial.new(
          line_item_material_breakdown: tender_line_item.line_item_material_breakdown,
          proportion_percentage: 101
        )
        expect(material).not_to be_valid
        expect(material.errors[:proportion_percentage]).to include("must be less than or equal to 100")
      end

      it "allows proportion_percentage > 100 for quantity-based categories" do
        material = LineItemMaterial.new(
          line_item_material_breakdown: bolt_line_item.line_item_material_breakdown,
          proportion_percentage: 150
        )
        # Set rate to avoid other validation errors if any
        material.rate = 100
        expect(material).to be_valid
      end
    end
  end
end
