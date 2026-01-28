require 'rails_helper'

RSpec.describe TenderLineItem, type: :model do
  let(:tender) { create(:tender) }

  describe 'defaults' do
    it 'sets include_in_tonnage to true by default' do
      line_item = TenderLineItem.new
      expect(line_item.include_in_tonnage).to be true
    end
  end

  describe 'inheritance from project rate buildup' do
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
      
      # Subtotal: 1000 (material) + 500 (fab) = 1500
      expect(rate_buildup.subtotal).to eq(1500)
      expect(rate_buildup.rounded_rate).to eq(1500)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:section_category).optional }
  end

  describe 'validations' do
    it 'requires section_category_id for non-headings' do
      line_item = build(:tender_line_item, tender: tender, section_category: nil, is_heading: false)
      expect(line_item).not_to be_valid
      expect(line_item.errors[:section_category_id]).to include("can't be blank")
    end

    it 'does not require section_category_id for headings' do
      line_item = build(:tender_line_item, tender: tender, section_category: nil, is_heading: true)
      expect(line_item).to be_valid
    end
  end

  describe 'heading positioning' do
    let(:tender) { create(:tender) }

    it 'assigns correct positions to headings and line items' do
      # Create a mix of headings and line items
      line_item_1 = create(:tender_line_item, tender: tender, item_description: "Item 1")
      heading_1 = create(:tender_line_item, tender: tender, is_heading: true, item_description: "Section A")
      line_item_2 = create(:tender_line_item, tender: tender, item_description: "Item 2")
      heading_2 = create(:tender_line_item, tender: tender, is_heading: true, item_description: "Section B")

      # Verify positions are sequential
      expect(line_item_1.position).to eq(1)
      expect(heading_1.position).to eq(2)
      expect(line_item_2.position).to eq(3)
      expect(heading_2.position).to eq(4)
    end

    it 'maintains position ordering when items are mixed' do
      items = []
      items << create(:tender_line_item, tender: tender, item_description: "Item A")
      items << create(:tender_line_item, tender: tender, is_heading: true, item_description: "Heading A")
      items << create(:tender_line_item, tender: tender, item_description: "Item B")
      items << create(:tender_line_item, tender: tender, is_heading: true, item_description: "Heading B")
      items << create(:tender_line_item, tender: tender, item_description: "Item C")

      # Verify ordered scope returns items in position order
      ordered_items = tender.tender_line_items.ordered
      expect(ordered_items.map(&:item_description)).to eq(["Item A", "Heading A", "Item B", "Heading B", "Item C"])
    end

    it 'allows manual reordering and maintains it' do
      item1 = create(:tender_line_item, tender: tender, item_description: "Item 1")
      item2 = create(:tender_line_item, tender: tender, item_description: "Item 2")
      item3 = create(:tender_line_item, tender: tender, item_description: "Item 3")

      expect(tender.tender_line_items.ordered.map(&:item_description)).to eq(["Item 1", "Item 2", "Item 3"])

      # Simulate reordering via controller logic
      item3.update_column(:position, 1)
      item1.update_column(:position, 2)
      item2.update_column(:position, 3)

      expect(tender.tender_line_items.ordered.map(&:item_description)).to eq(["Item 3", "Item 1", "Item 2"])
    end
  end

  describe "category synchronization" do
    let(:tender) { create(:tender) }
    let(:category1) { create(:section_category) }
    let(:category2) { create(:section_category) }
    let(:line_item) { create(:tender_line_item, tender: tender, section_category: category1) }
    
    it "repopulates materials when category changes" do
      # Create template for category2
      template = create(:section_category_template, section_category: category2)
      material_supply = create(:material_supply, waste_percentage: 0)
      # Ensure tender specific rate exists and has the right rate
      rate = tender.tender_specific_material_rates.find_or_initialize_by(
        material_supply_id: material_supply.id,
        material_supply_type: 'MaterialSupply'
      )
      rate.update!(rate: 100)
      
      create(:line_item_material_template, section_category_template: template, material_supply: material_supply, proportion_percentage: 100, waste_percentage: 0)
      
      # Ensure breakdown exists and has 0 rounding/margin
      breakdown = line_item.line_item_material_breakdown || line_item.create_line_item_material_breakdown
      breakdown.update!(rounding_interval: 0, margin_percentage: 0)
      
      # Change category
      line_item.update!(section_category: category2)
      
      # Check that materials were created
      expect(line_item.line_item_materials.count).to eq(1)
      expect(line_item.line_item_rate_build_up.material_supply_rate).to eq(100)
    end
    
    it "clears materials when changing to category without template" do
      # Start with category that has materials
      template = create(:section_category_template, section_category: category1)
      material_supply = create(:material_supply)
      # Ensure tender specific rate exists and has the right rate
      rate = tender.tender_specific_material_rates.find_or_initialize_by(
        material_supply_id: material_supply.id,
        material_supply_type: 'MaterialSupply'
      )
      rate.update!(rate: 100)
      
      create(:line_item_material_template, section_category_template: template, material_supply: material_supply, proportion_percentage: 100)
      
      line_item.line_item_material_breakdown.populate_from_category(category1.id)
      expect(line_item.line_item_materials.count).to eq(1)
      
      # Change to category without template
      line_item.update!(section_category: category2)
      
      expect(line_item.line_item_materials.count).to eq(0)
      expect(line_item.line_item_rate_build_up.material_supply_rate).to eq(0)
    end
  end
end
