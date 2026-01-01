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
  end
end
