require 'rails_helper'

RSpec.describe Tender, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:p_and_g_display_mode) }
    it { should validate_inclusion_of(:p_and_g_display_mode).in_array(%w(detailed rolled_up)) }
    it { should validate_presence_of(:shop_drawings_display_mode) }
    it { should validate_inclusion_of(:shop_drawings_display_mode).in_array(%w(lump_sum tonnage_rate)) }
  end

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

  describe '#report_expiration_date' do
    let(:tender) { create(:tender) }

    context 'without submission_deadline' do
      it 'returns 30 days from today' do
        expected_date = Date.current + 30.days
        expect(tender.report_expiration_date).to eq(expected_date)
      end

      it 'updates daily as time passes' do
        first_date = Date.current + 30.days
        
        travel_to 5.days.from_now do
          second_date = Date.current + 30.days
          future_expiration = tender.report_expiration_date
          # Both should be different (5 days apart)
          expect(second_date).not_to eq(first_date)
          expect(future_expiration).to eq(second_date)
        end
      end
    end

    context 'with submission_deadline set' do
      it 'returns submission_deadline instead of 30-day calculation' do
        deadline = Date.current + 15.days
        tender.update!(submission_deadline: deadline)
        
        expect(tender.report_expiration_date).to eq(deadline)
      end

      it 'remains constant even when time passes' do
        deadline = Date.current + 15.days
        tender.update!(submission_deadline: deadline)
        
        expect(tender.report_expiration_date).to eq(deadline)
        
        travel_to 5.days.from_now do
          expect(tender.report_expiration_date).to eq(deadline)
        end
      end
    end
  end

  describe '#recalculate_total_tonnage!' do
    let(:tender) { create(:tender) }

    context 'with line items and headings' do
      it 'excludes headings from tonnage calculation' do
        # Create a regular line item with include_in_tonnage: true
        create(:tender_line_item, tender: tender, include_in_tonnage: true, quantity: 10)

        # Create a heading with include_in_tonnage: true (should be ignored)
        create(:tender_line_item, tender: tender, is_heading: true, include_in_tonnage: true, quantity: 999)

        tender.recalculate_total_tonnage!

        # Expected: Only the line item contributes (10 tonnes)
        expect(tender.total_tonnage).to eq(10)
      end

      it 'sums items with include_in_tonnage set to true' do
        create(:tender_line_item, tender: tender, include_in_tonnage: true, quantity: 5)
        create(:tender_line_item, tender: tender, include_in_tonnage: true, quantity: 3)

        tender.recalculate_total_tonnage!

        expect(tender.total_tonnage).to eq(8)
      end

      it 'ignores items with include_in_tonnage set to false' do
        create(:tender_line_item, tender: tender, include_in_tonnage: true, quantity: 10)
        create(:tender_line_item, tender: tender, include_in_tonnage: false, quantity: 5)

        tender.recalculate_total_tonnage!

        # Expected: Only the included item contributes
        expect(tender.total_tonnage).to eq(10)
      end

      it 'sums items regardless of unit when include_in_tonnage is true' do
        create(:tender_line_item, tender: tender, include_in_tonnage: true, unit_of_measure: 'each', quantity: 10)
        create(:tender_line_item, tender: tender, include_in_tonnage: true, unit_of_measure: 'kg', quantity: 5)

        tender.recalculate_total_tonnage!

        # Expected: Both are summed because include_in_tonnage is true
        expect(tender.total_tonnage).to eq(15)
      end
    end

    context 'with only headings' do
      it 'returns zero when all items are headings' do
        create(:tender_line_item, tender: tender, is_heading: true, include_in_tonnage: true, quantity: 100)

        tender.recalculate_total_tonnage!

        expect(tender.total_tonnage).to eq(0)
      end
    end

    describe "P&G sync cascade" do
      let!(:crane_breakdown) { create(:on_site_mobile_crane_breakdown, tender: tender) }
      let!(:summary) { create(:tender_equipment_summary, tender: tender) }
      let!(:crane_pg_item) { create(:preliminaries_general_item, tender: tender, is_crane: true, category: 'fixed', description: 'Crane') }
      let!(:access_pg_item) { create(:preliminaries_general_item, tender: tender, is_access_equipment: true, category: 'fixed', description: 'Access') }

      it "triggers a rate update on P&G items when tonnage changes" do
        # Setup initial stubs
        allow_any_instance_of(OnSiteMobileCraneBreakdown).to receive(:crainage_rate_per_tonne).and_return(2000.0)
        allow_any_instance_of(TenderEquipmentSummary).to receive(:cherry_picker_rate_per_tonne).and_return(1500.0)
        
        # Initial sync
        crane_pg_item.save!
        access_pg_item.save!
        
        expect(crane_pg_item.reload.rate).to eq(2000.0)
        expect(access_pg_item.reload.rate).to eq(1500.0)

        # Change tonnage-dependent rates
        allow_any_instance_of(OnSiteMobileCraneBreakdown).to receive(:crainage_rate_per_tonne).and_return(3000.0)
        allow_any_instance_of(TenderEquipmentSummary).to receive(:cherry_picker_rate_per_tonne).and_return(2500.0)

        # Trigger tonnage recalculation
        create(:tender_line_item, tender: tender, unit_of_measure: 'tonnes', quantity: 50)
        tender.recalculate_total_tonnage!

        expect(crane_pg_item.reload.rate).to eq(3000.0)
        expect(access_pg_item.reload.rate).to eq(2500.0)
      end
    end
  end

  describe '#rate_per_tonne' do
    let(:tender) { create(:tender, grand_total: 1000, total_tonnage: 2) }

    it 'calculates rate per tonne correctly' do
      tender.update_columns(grand_total: 1000, total_tonnage: 2)
      expect(tender.rate_per_tonne).to eq(500)
    end

    it 'returns 0 if total_tonnage is 0' do
      tender.total_tonnage = 0
      expect(tender.rate_per_tonne).to eq(0)
    end

    it 'handles nil values gracefully' do
      tender.grand_total = nil
      tender.total_tonnage = nil
      expect(tender.rate_per_tonne).to eq(0)
    end
  end

  describe 'broadcasting' do
    let(:tender) { create(:tender) }

    it 'broadcasts rate per tonne update when grand total is recalculated' do
      expect(tender).to receive(:broadcast_update_rate_per_tonne)
      tender.recalculate_grand_total!
    end

    it 'broadcasts rate per tonne update when total tonnage is recalculated' do
      expect(tender).to receive(:broadcast_update_rate_per_tonne)
      tender.recalculate_total_tonnage!
    end
  end
end
