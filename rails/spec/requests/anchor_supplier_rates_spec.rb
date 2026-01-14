require 'rails_helper'

RSpec.describe "AnchorSupplierRates", type: :request do
  let(:user) { User.create!(email: "test@example.com", password: "password", role: "admin") }
  let(:anchor_rate) { AnchorRate.create!(name: "Anchor 1", material_cost: 0) }
  let(:supplier) { Supplier.create!(name: "Hilti") }

  before do
    sign_in user
  end

  describe "POST /anchor_supplier_rates" do
    it "creates a new anchor_supplier_rate and returns JSON" do
      expect {
        post anchor_supplier_rates_path, params: {
          anchor_supplier_rate: {
            anchor_rate_id: anchor_rate.id,
            supplier_id: supplier.id,
            rate: 125.50
          }
        }, as: :json
      }.to change(AnchorSupplierRate, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to include("success" => true, "id" => anything)
    end
  end

  describe "PATCH /anchor_supplier_rates/:id" do
    let!(:rate) { AnchorSupplierRate.create!(anchor_rate: anchor_rate, supplier: supplier, rate: 100) }

    it "updates the rate and returns JSON" do
      patch anchor_supplier_rate_path(rate), params: {
        anchor_supplier_rate: {
          rate: 150.00
        }
      }, as: :json

      expect(response).to have_http_status(:success)
      expect(rate.reload.rate).to eq(150.00)
    end

    it "updates the winner and syncs to anchor_rate" do
      patch anchor_supplier_rate_path(rate), params: {
        anchor_supplier_rate: {
          is_winner: true
        }
      }, as: :json

      expect(rate.reload.is_winner).to be true
      expect(anchor_rate.reload.material_cost).to eq(100.00)
    end
  end

  describe "DELETE /anchor_supplier_rates/:id" do
    let!(:rate) { AnchorSupplierRate.create!(anchor_rate: anchor_rate, supplier: supplier, rate: 100) }

    it "destroys the rate and returns JSON with updated cost" do
      expect {
        delete anchor_supplier_rate_path(rate), as: :json
      }.to change(AnchorSupplierRate, :count).by(-1)

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to include("success" => true, "anchor_rate_material_cost" => "0.0")
    end
  end
end
