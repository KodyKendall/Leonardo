require 'rails_helper'

RSpec.describe Tender, type: :model do
  describe '#recalculate_grand_total!' do
    let(:tender) { create(:tender) }

    context 'with line items and headings' do
      it 'excludes headings from grand total calculation' do
        # Setup: Create project rate buildup with known rates
        tender.reload.project_rate_buildup.update!(
          material_supply_rate: 100,
          fabrication_rate: 50,
          overheads_rate: 0,
          shop_priming_rate: 0,
          onsite_painting_rate: 0,
          delivery_rate: 0,
          bolts_rate: 0,
          erection_rate: 0,
          crainage_rate: 0,
          cherry_picker_rate: 0,
          galvanizing_rate: 0,
          shop_drawings_rate: 0
        )

        # Create a regular line item: rate = 150 (100 + 50), qty = 2, total = 300
        line_item = create(:tender_line_item, tender: tender, quantity: 2)
        line_item.line_item_rate_build_up.update!(material_supply_rate: 100, fabrication_rate: 50)
        line_item.line_item_rate_build_up.recalculate_totals!

        # Create a heading: should NOT contribute to total
        heading = create(:tender_line_item, tender: tender, is_heading: true, item_description: "Section 1", quantity: 999)

        # Recalculate and verify
        tender.recalculate_grand_total!
        
        # Expected: Only line_item contributes (150 * 2 = 300), heading is ignored
        expect(tender.grand_total).to eq(300)
      end

      it 'correctly sums multiple line items while ignoring headings' do
        tender.reload.project_rate_buildup.update!(
          material_supply_rate: 100,
          fabrication_rate: 0,
          overheads_rate: 0,
          shop_priming_rate: 0,
          onsite_painting_rate: 0,
          delivery_rate: 0,
          bolts_rate: 0,
          erection_rate: 0,
          crainage_rate: 0,
          cherry_picker_rate: 0,
          galvanizing_rate: 0,
          shop_drawings_rate: 0
        )

        # Create multiple line items
        line_item_1 = create(:tender_line_item, tender: tender, quantity: 1)
        line_item_1.line_item_rate_build_up.update!(material_supply_rate: 100)
        line_item_1.line_item_rate_build_up.recalculate_totals!

        line_item_2 = create(:tender_line_item, tender: tender, quantity: 2)
        line_item_2.line_item_rate_build_up.update!(material_supply_rate: 100)
        line_item_2.line_item_rate_build_up.recalculate_totals!

        # Create headings between them
        heading_1 = create(:tender_line_item, tender: tender, is_heading: true, item_description: "Part A")
        heading_2 = create(:tender_line_item, tender: tender, is_heading: true, item_description: "Part B")

        tender.recalculate_grand_total!

        # Expected: 100*1 + 100*2 = 300 (headings ignored)
        expect(tender.grand_total).to eq(300)
      end
    end

    context 'with only headings' do
      it 'returns zero when all items are headings' do
        create(:tender_line_item, tender: tender, is_heading: true, item_description: "Heading 1")
        create(:tender_line_item, tender: tender, is_heading: true, item_description: "Heading 2")

        tender.recalculate_grand_total!

        expect(tender.grand_total).to eq(0)
      end
    end
  end

  describe '#recalculate_total_tonnage!' do
    let(:tender) { create(:tender) }

    context 'with line items and headings in tonnage units' do
      it 'excludes headings from tonnage calculation' do
        # Create a regular line item with weight unit
        create(:tender_line_item, tender: tender, unit_of_measure: 'tonnes', quantity: 10)

        # Create a heading with a weight unit (should be ignored)
        create(:tender_line_item, tender: tender, is_heading: true, unit_of_measure: 'tonnes', quantity: 999)

        tender.recalculate_total_tonnage!

        # Expected: Only the line item contributes (10 tonnes)
        expect(tender.total_tonnage).to eq(10)
      end

      it 'correctly sums multiple weight units while ignoring headings' do
        create(:tender_line_item, tender: tender, unit_of_measure: 'tonnes', quantity: 5)
        create(:tender_line_item, tender: tender, unit_of_measure: 'tons', quantity: 3)

        # Heading with weight unit (should be ignored)
        create(:tender_line_item, tender: tender, is_heading: true, unit_of_measure: 'tonnes', quantity: 500)

        tender.recalculate_total_tonnage!

        # Expected: 5 + 3 = 8 (heading ignored)
        expect(tender.total_tonnage).to eq(8)
      end

      it 'ignores non-weight units regardless of heading status' do
        create(:tender_line_item, tender: tender, unit_of_measure: 'each', quantity: 10)
        create(:tender_line_item, tender: tender, is_heading: true, unit_of_measure: 'each', quantity: 5)

        tender.recalculate_total_tonnage!

        # Expected: Non-weight units are ignored
        expect(tender.total_tonnage).to eq(0)
      end
    end

    context 'with only headings in weight units' do
      it 'returns zero when all weight items are headings' do
        create(:tender_line_item, tender: tender, is_heading: true, unit_of_measure: 'tonnes', quantity: 100)
        create(:tender_line_item, tender: tender, is_heading: true, unit_of_measure: 'tons', quantity: 50)

        tender.recalculate_total_tonnage!

        expect(tender.total_tonnage).to eq(0)
      end
    end
  end
end
