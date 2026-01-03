require 'rails_helper'

RSpec.describe PopulateTenderMaterialRates, type: :model do
  let(:tender) { create(:tender) }
  let(:material_supply) { create(:material_supply) }
  let(:supplier) { create(:supplier) }
  let(:month_jan) { create(:monthly_material_supply_rate, effective_from: Date.new(2026, 1, 1), effective_to: Date.new(2026, 1, 31)) }
  let(:month_feb) { create(:monthly_material_supply_rate, effective_from: Date.new(2026, 2, 1), effective_to: Date.new(2026, 2, 28)) }

  describe '#execute' do
    context 'when a specific month is provided' do
      it 'populates rates using the winner from that month' do
        winner_rate = create(:material_supply_rate, 
          monthly_material_supply_rate: month_jan, 
          material_supply: material_supply, 
          rate: 100.0, 
          is_winner: true
        )
        create(:material_supply_rate, 
          monthly_material_supply_rate: month_jan, 
          material_supply: material_supply, 
          rate: 50.0, 
          is_winner: false # cheaper but not winner
        )

        service = PopulateTenderMaterialRates.new(tender, monthly_material_supply_rate: month_jan)
        service.execute

        tender_rate = tender.tender_specific_material_rates.find_by(material_supply: material_supply)
        expect(tender_rate.rate).to eq(100.0)
      end

      it 'populates rates using the cheapest if no winner exists' do
        create(:material_supply_rate, 
          monthly_material_supply_rate: month_jan, 
          material_supply: material_supply, 
          rate: 200.0, 
          is_winner: false
        )
        create(:material_supply_rate, 
          monthly_material_supply_rate: month_jan, 
          material_supply: material_supply, 
          rate: 150.0, 
          is_winner: false
        )

        service = PopulateTenderMaterialRates.new(tender, monthly_material_supply_rate: month_jan)
        service.execute

        tender_rate = tender.tender_specific_material_rates.find_by(material_supply: material_supply)
        expect(tender_rate.rate).to eq(150.0)
      end

      it 'overrides existing rates when switching months' do
        # Jan rate
        create(:material_supply_rate, monthly_material_supply_rate: month_jan, material_supply: material_supply, rate: 100.0, is_winner: true)
        PopulateTenderMaterialRates.new(tender, monthly_material_supply_rate: month_jan).execute
        
        expect(tender.tender_specific_material_rates.find_by(material_supply: material_supply).rate).to eq(100.0)

        # Feb rate
        create(:material_supply_rate, monthly_material_supply_rate: month_feb, material_supply: material_supply, rate: 120.0, is_winner: true)
        PopulateTenderMaterialRates.new(tender, monthly_material_supply_rate: month_feb).execute

        expect(tender.tender_specific_material_rates.find_by(material_supply: material_supply).rate).to eq(120.0)
      end
    end

    context 'when no month is provided' do
      it 'defaults to the current active month' do
        current_month = create(:monthly_material_supply_rate, 
          effective_from: Date.current.beginning_of_month, 
          effective_to: Date.current.end_of_month
        )
        create(:material_supply_rate, 
          monthly_material_supply_rate: current_month, 
          material_supply: material_supply, 
          rate: 300.0, 
          is_winner: true
        )

        service = PopulateTenderMaterialRates.new(tender)
        service.execute

        tender_rate = tender.tender_specific_material_rates.find_by(material_supply: material_supply)
        expect(tender_rate.rate).to eq(300.0)
      end
    end
  end
end
