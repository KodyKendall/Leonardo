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
end
