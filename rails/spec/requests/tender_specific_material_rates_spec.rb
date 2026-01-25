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

    it "fails with validation error if rate is negative" do
      patch tender_tender_specific_material_rate_path(tender, rate), params: {
        tender_specific_material_rate: { rate: -1.0 }
      }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(rate.reload.rate).to eq(100.0)
    end

    context "when cascade confirmation is required" do
      let!(:line_item) { create(:tender_line_item, tender: tender) }
      let!(:breakdown) { create(:line_item_material_breakdown, tender_line_item: line_item) }
      let!(:line_item_material) do
        create(:line_item_material, 
               tender_line_item: line_item, 
               line_item_material_breakdown: breakdown,
               material_supply_id: rate.material_supply_id, 
               material_supply_type: rate.material_supply_type)
      end

      it "renders the confirmation partial if confirm_cascade is missing" do
        patch tender_tender_specific_material_rate_path(tender, rate), params: {
          tender_specific_material_rate: { rate: 200.0 }
        }, as: :turbo_stream

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Confirm Rate Update")
        expect(rate.reload.rate).to eq(100.0)
      end

      it "updates the rate if confirm_cascade is present" do
        patch tender_tender_specific_material_rate_path(tender, rate), params: {
          tender_specific_material_rate: { rate: 200.0 },
          confirm_cascade: "true"
        }, as: :turbo_stream

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("Confirm Rate Update")
        expect(rate.reload.rate).to eq(200.0)
      end
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
