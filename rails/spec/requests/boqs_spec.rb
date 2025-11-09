require 'rails_helper'

RSpec.describe "Boqs", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/boqs/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/boqs/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/boqs/create"
      expect(response).to have_http_status(:success)
    end
  end

end
