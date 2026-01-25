require 'rails_helper'

RSpec.describe "TenderSpecificMaterialRates", type: :request do
  let(:user) { create(:user) }
  let(:tender) { create(:tender) }
  let(:monthly_rate) { create(:monthly_material_supply_rate) }
  let(:material) { create(:material_supply) }
  let(:supplier) { create(:supplier) }

  before do
    sign_in user
  end

  describe "GET /tenders/:tender_id/tender_specific_material_rates/lookup" do
    it "returns rate for matching (monthly_rate_id, material_supply_id, supplier_id)" do
      create(:material_supply_rate, 
             monthly_material_supply_rate: monthly_rate, 
             material_supply: material, 
             supplier: supplier, 
             rate: 2000.0)

      get lookup_tender_tender_specific_material_rates_path(tender), params: {
        monthly_rate_id: monthly_rate.id,
        material_supply_id: material.id,
        supplier_id: supplier.id
      }, as: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      # Decimals might be returned as strings or floats depending on JSON encoder
      expect(json['rate'].to_f).to eq(2000.0)
    end

    it "returns nil rate if no matching record" do
      get lookup_tender_tender_specific_material_rates_path(tender), params: {
        monthly_rate_id: monthly_rate.id,
        material_supply_id: material.id,
        supplier_id: supplier.id
      }, as: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['rate']).to be_nil
    end
  end

  describe "GET /tenders/:tender_id/tender_specific_material_rates/:id" do
    let!(:rate) { create(:tender_specific_material_rate, tender: tender) }

    it "returns success and renders the partial" do
      get tender_tender_specific_material_rate_path(tender, rate)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("turbo-frame id=\"tender_specific_material_rate_#{rate.id}\"")
    end
  end

  describe "PATCH /tenders/:tender_id/tender_specific_material_rates/:id" do
    let!(:rate) { create(:tender_specific_material_rate, tender: tender, rate: 100.0) }

    it "updates the record successfully" do
      patch tender_tender_specific_material_rate_path(tender, rate), params: {
        tender_specific_material_rate: { rate: 150.0 }
      }, as: :turbo_stream

      expect(response).to have_http_status(:success)
      expect(rate.reload.rate).to eq(150.0)
    end
  end

  describe "DELETE /tenders/:tender_id/tender_specific_material_rates/:id" do
    let!(:rate) { create(:tender_specific_material_rate, tender: tender) }

    it "removes the record" do
      expect {
        delete tender_tender_specific_material_rate_path(tender, rate), as: :turbo_stream
      }.to change(TenderSpecificMaterialRate, :count).by(-1)
      
      expect(response).to have_http_status(:success)
    end
  end
end
