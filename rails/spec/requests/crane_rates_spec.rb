require 'rails_helper'

RSpec.describe "/crane_rates", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  let(:valid_attributes) {
    { size: '50t', ownership_type: 'rsb_owned', dry_rate_per_day: 5000.0, diesel_per_day: 500.0, effective_from: Date.current }
  }

  let(:invalid_attributes) {
    { size: '', ownership_type: '', dry_rate_per_day: -100, diesel_per_day: -50 }
  }

  describe "GET /index" do
    it "renders a successful response" do
      sign_in admin_user
      create(:crane_rate)
      get crane_rates_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      sign_in admin_user
      crane_rate = create(:crane_rate)
      get crane_rate_url(crane_rate)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response for admin users" do
      sign_in admin_user
      get new_crane_rate_url
      expect(response).to be_successful
    end

    it "redirects non-admin users" do
      sign_in regular_user
      get new_crane_rate_url
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /edit" do
    it "renders a successful response for admin users" do
      sign_in admin_user
      crane_rate = create(:crane_rate)
      get edit_crane_rate_url(crane_rate)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new CraneRate" do
        sign_in admin_user
        expect {
          post crane_rates_url, params: { crane_rate: valid_attributes }
        }.to change(CraneRate, :count).by(1)
      end

      it "redirects to the created crane_rate" do
        sign_in admin_user
        post crane_rates_url, params: { crane_rate: valid_attributes }
        expect(response).to redirect_to(crane_rate_url(CraneRate.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new CraneRate" do
        sign_in admin_user
        expect {
          post crane_rates_url, params: { crane_rate: invalid_attributes }
        }.to change(CraneRate, :count).by(0)
      end

      it "renders a response with 422 status" do
        sign_in admin_user
        post crane_rates_url, params: { crane_rate: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "for non-admin users" do
      it "redirects to root" do
        sign_in regular_user
        post crane_rates_url, params: { crane_rate: valid_attributes }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        { dry_rate_per_day: 6000.0 }
      }

      it "updates the requested crane_rate" do
        sign_in admin_user
        crane_rate = create(:crane_rate)
        patch crane_rate_url(crane_rate), params: { crane_rate: new_attributes }
        crane_rate.reload
        expect(crane_rate.dry_rate_per_day).to eq(6000.0)
      end

      it "redirects to the crane_rate" do
        sign_in admin_user
        crane_rate = create(:crane_rate)
        patch crane_rate_url(crane_rate), params: { crane_rate: new_attributes }
        expect(response).to redirect_to(crane_rate_url(crane_rate))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status" do
        sign_in admin_user
        crane_rate = create(:crane_rate)
        patch crane_rate_url(crane_rate), params: { crane_rate: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested crane_rate" do
      sign_in admin_user
      crane_rate = create(:crane_rate)
      expect {
        delete crane_rate_url(crane_rate)
      }.to change(CraneRate, :count).by(-1)
    end

    it "redirects to the crane_rates list" do
      sign_in admin_user
      crane_rate = create(:crane_rate)
      delete crane_rate_url(crane_rate)
      expect(response).to redirect_to(crane_rates_url)
    end
  end
end
