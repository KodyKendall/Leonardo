require 'rails_helper'

RSpec.describe ProjectRateBuildUp, type: :model do
  describe 'associations' do
    it { should belong_to(:tender) }
  end

  describe 'validations' do
    it { should validate_presence_of(:tender_id) }
    it { should validate_numericality_of(:crainage_rate).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe 'persistence' do
    let(:tender) { create(:tender) }
    let(:project_rate_build_up) { tender.reload.project_rate_buildup }

    it 'can save and retrieve delivery_rate_note' do
      project_rate_build_up.update!(delivery_rate_note: "Bulk discount")
      expect(project_rate_build_up.reload.delivery_rate_note).to eq("Bulk discount")
    end
  end

  describe '#calculate_crainage_rate' do
    let(:tender) { create(:tender, total_tonnage: 100) }
    let(:project_rate_build_up) { tender.reload.project_rate_buildup }

    context 'when tender has no crane breakdown' do
      it 'sets crainage_rate to 0' do
        project_rate_build_up.calculate_crainage_rate
        expect(project_rate_build_up.crainage_rate).to eq(0)
      end
    end

    context 'when tender has crane breakdown but no crane selections' do
      before do
        create(:on_site_mobile_crane_breakdown, tender: tender)
      end

      it 'sets crainage_rate to 0' do
        project_rate_build_up.calculate_crainage_rate
        expect(project_rate_build_up.crainage_rate).to eq(0)
      end
    end

    context 'when tender has crane breakdown with crane selections' do
      let!(:crane_breakdown) { create(:on_site_mobile_crane_breakdown, tender: tender) }
      # Create crane_rate with specific rates for predictable calculations
      # wet_rate_per_day = dry_rate + diesel = 400 + 0 = 400
      let(:crane_rate) { create(:crane_rate, dry_rate_per_day: 400, diesel_per_day: 0) }

      before do
        # Total cost = quantity * duration * wet_rate = 1 * 10 * 400 = 4000
        create(:tender_crane_selection, tender: tender, crane_rate: crane_rate, purpose: 'main',
               quantity: 1, duration_days: 10)
        # Total cost = 1 * 10 * 400 = 4000
        create(:tender_crane_selection, tender: tender, crane_rate: crane_rate, purpose: 'main',
               quantity: 1, duration_days: 10)
        # Reload to get fresh data
        tender.reload
      end

      it 'calculates crainage_rate from total crane cost divided by tonnage (rounded to nearest R20)' do
        # Total crane cost = 4000 + 4000 = 8000
        # Tonnage = 100
        # Rate = 8000 / 100 = 80
        # Rounded to nearest R20 ceiling = 80
        project_rate_build_up.calculate_crainage_rate
        expect(project_rate_build_up.crainage_rate).to eq(80)
      end
    end

    context 'when tender has zero tonnage' do
      let(:tender) { create(:tender, total_tonnage: 0) }
      let!(:crane_breakdown) { create(:on_site_mobile_crane_breakdown, tender: tender) }
      let(:crane_rate) { create(:crane_rate, dry_rate_per_day: 400, diesel_per_day: 0) }

      before do
        create(:tender_crane_selection, tender: tender, crane_rate: crane_rate, purpose: 'main',
               quantity: 1, duration_days: 10)
        tender.reload
      end

      it 'sets crainage_rate to 0 (avoids division by zero)' do
        project_rate_build_up.calculate_crainage_rate
        expect(project_rate_build_up.crainage_rate).to eq(0)
      end
    end

    context 'when tender is nil' do
      let(:project_rate_build_up) { build(:project_rate_build_up, tender: nil) }

      it 'returns early without changing crainage_rate' do
        original_rate = project_rate_build_up.crainage_rate
        project_rate_build_up.calculate_crainage_rate
        expect(project_rate_build_up.crainage_rate).to eq(original_rate)
      end
    end
  end

  describe 'before_save callback' do
    let(:tender) { create(:tender, total_tonnage: 200) }
    let(:project_rate_build_up) { tender.reload.project_rate_buildup }
    let!(:crane_breakdown) { create(:on_site_mobile_crane_breakdown, tender: tender) }
    # wet_rate_per_day = 500 + 0 = 500
    let(:crane_rate) { create(:crane_rate, dry_rate_per_day: 500, diesel_per_day: 0) }

    before do
      # Total cost = 1 * 20 * 500 = 10000
      create(:tender_crane_selection, tender: tender, crane_rate: crane_rate, purpose: 'main',
             quantity: 1, duration_days: 20)
      tender.reload
    end

    it 'automatically calculates crainage_rate on save' do
      # Total crane cost = 10000
      # Tonnage = 200
      # Rate = 10000 / 200 = 50
      # Rounded to nearest R20 ceiling = 60
      project_rate_build_up.save!
      expect(project_rate_build_up.crainage_rate).to eq(60)
    end

    it 'recalculates crainage_rate when other attributes change' do
      project_rate_build_up.fabrication_rate = 15.0
      project_rate_build_up.save!
      expect(project_rate_build_up.crainage_rate).to eq(60)
    end
  end

  describe 'crainage_rate rounding' do
    let(:tender) { create(:tender, total_tonnage: 100) }
    let(:project_rate_build_up) { tender.reload.project_rate_buildup }
    let!(:crane_breakdown) { create(:on_site_mobile_crane_breakdown, tender: tender) }

    it 'rounds up to nearest R20 using ceiling' do
      # wet_rate = 810 + 0 = 810
      # Total cost = 1 * 10 * 810 = 8100, tonnage = 100
      # Rate = 81, ceiling to R20 = 100
      crane_rate = create(:crane_rate, dry_rate_per_day: 810, diesel_per_day: 0)
      create(:tender_crane_selection, tender: tender, crane_rate: crane_rate, purpose: 'main',
             quantity: 1, duration_days: 10)
      tender.reload
      project_rate_build_up.calculate_crainage_rate
      expect(project_rate_build_up.crainage_rate).to eq(100)
    end

    it 'keeps exact multiples of R20 unchanged' do
      # wet_rate = 600 + 0 = 600
      # Total cost = 1 * 10 * 600 = 6000, tonnage = 100
      # Rate = 60, ceiling to R20 = 60
      crane_rate = create(:crane_rate, dry_rate_per_day: 600, diesel_per_day: 0)
      create(:tender_crane_selection, tender: tender, crane_rate: crane_rate, purpose: 'main',
             quantity: 1, duration_days: 10)
      tender.reload
      project_rate_build_up.calculate_crainage_rate
      expect(project_rate_build_up.crainage_rate).to eq(60)
    end
  end

  describe '#sync_rates_to_child_line_items' do
    let(:tender) { create(:tender) }
    let(:project_rate_buildup) { tender.reload.project_rate_buildup }
    let!(:line_item) { create(:tender_line_item, tender: tender) }
    let(:rate_buildup) { line_item.line_item_rate_build_up }

    it 'syncs changed rates to all child line items' do
      project_rate_buildup.update!(
        material_supply_rate: 5500,
        profit_margin_percentage: 15
      )

      rate_buildup.reload
      expect(rate_buildup.material_supply_rate).to eq(5500)
      expect(rate_buildup.margin_percentage).to eq(15)
    end
  end
end
