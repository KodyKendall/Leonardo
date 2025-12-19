require 'rails_helper'

RSpec.describe "TenderSpecificMaterialRates", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/tender_specific_material_rates/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/tender_specific_material_rates/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/tender_specific_material_rates/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/tender_specific_material_rates/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/tender_specific_material_rates/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/tender_specific_material_rates/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
