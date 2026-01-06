require 'rails_helper'

RSpec.describe TenderInclusionsExclusion, type: :model do
  describe "syncing inclusions to line items" do
    let(:tender) { create(:tender) }
    let!(:inclusions) { create(:tender_inclusions_exclusion, tender: tender, fabrication_included: false, delivery_included: false) }
    let!(:line_items) { create_list(:tender_line_item, 5, tender: tender) }

    it "percolates changes from tender inclusions to all associated line item rate buildups" do
      # Initial check: verify line items started with false (0.0) for fabrication
      line_items.each do |li|
        expect(li.line_item_rate_build_up.fabrication_included).to eq(0.0)
        expect(li.line_item_rate_build_up.delivery_included).to eq(0.0)
      end

      # Update tender inclusions
      inclusions.update!(fabrication_included: true, delivery_included: true)

      # Verify percolation - query directly from DB to avoid association caching
      line_items.each do |li|
        rate_buildup = LineItemRateBuildUp.find(li.line_item_rate_build_up.id)
        expect(rate_buildup.fabrication_included).to eq(1.0)
        expect(rate_buildup.delivery_included).to eq(1.0)
      end
    end

    it "handles field name mismatches correctly (e.g., primer to shop_priming)" do
      # primer_included (TenderInclusionsExclusion) -> shop_priming_included (LineItemRateBuildUp)
      inclusions.update!(primer_included: true)

      line_items.each do |li|
        rate_buildup = LineItemRateBuildUp.find(li.line_item_rate_build_up.id)
        expect(rate_buildup.shop_priming_included).to eq(1.0)
      end

      inclusions.update!(primer_included: false)

      line_items.each do |li|
        rate_buildup = LineItemRateBuildUp.find(li.line_item_rate_build_up.id)
        expect(rate_buildup.shop_priming_included).to eq(0.0)
      end
    end

    it "only updates fields that were changed in the TenderInclusionsExclusion" do
      # Set an initial manual override on one line item
      target_li = line_items.first
      target_li.line_item_rate_build_up.update_columns(fabrication_included: 0.5)
      
      # Update a DIFFERENT field on the tender inclusions (e.g., delivery)
      inclusions.update!(delivery_included: true)

      # Verify fabrication_included was PRESERVED on the override item - query from DB
      target_rate_buildup = LineItemRateBuildUp.find(target_li.line_item_rate_build_up.id)
      expect(target_rate_buildup.fabrication_included).to eq(0.5)
      
      # Verify delivery_included was UPDATED on all items - query from DB
      line_items.each do |li|
        rate_buildup = LineItemRateBuildUp.find(li.line_item_rate_build_up.id)
        expect(rate_buildup.delivery_included).to eq(1.0)
      end
    end

    describe "#sync_all_to_line_items!" do
      it "updates ALL fields on all associated rate buildups regardless of previous state" do
        # Manually set all rate buildup fields to something else (e.g., 0.5) to ensure they get overwritten
        line_items.each do |li|
          li.line_item_rate_build_up.update_columns(
            fabrication_included: 0.5,
            overheads_included: 0.5,
            shop_priming_included: 0.5,
            onsite_painting_included: 0.5,
            delivery_included: 0.5,
            bolts_included: 0.5,
            erection_included: 0.5,
            crainage_included: 0.5,
            cherry_picker_included: 0.5,
            galvanizing_included: 0.5
          )
        end

        # Set specific values on inclusions
        inclusions.update_columns(
          fabrication_included: true,
          overheads_included: false,
          primer_included: true,
          final_paint_included: false,
          delivery_included: true,
          bolts_included: false,
          erection_included: true,
          crainage_included: false,
          cherry_pickers_included: true,
          steel_galvanized: false
        )

        # Trigger full sync
        inclusions.sync_all_to_line_items!

        # Verify all fields match the inclusions
        line_items.each do |li|
          rb = li.line_item_rate_build_up.reload
          expect(rb.fabrication_included).to eq(1.0)
          expect(rb.overheads_included).to eq(0.0)
          expect(rb.shop_priming_included).to eq(1.0)
          expect(rb.onsite_painting_included).to eq(0.0)
          expect(rb.delivery_included).to eq(1.0)
          expect(rb.bolts_included).to eq(0.0)
          expect(rb.erection_included).to eq(1.0)
          expect(rb.crainage_included).to eq(0.0)
          expect(rb.cherry_picker_included).to eq(1.0)
          expect(rb.galvanizing_included).to eq(0.0)
        end
      end
    end
  end
end
