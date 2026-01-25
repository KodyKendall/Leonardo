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
end
