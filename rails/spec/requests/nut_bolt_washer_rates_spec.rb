require 'rails_helper'

RSpec.describe "/nuts_bolts_and_washers", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user, :quantity_surveyor) }
  let(:valid_attributes) { { name: 'M12 Nut', waste_percentage: 7.5, material_cost: 15.0, calculation_breakdown: 'Test breakdown', mass_per_each: 0.123 } }
  let(:invalid_attributes) { { name: '', waste_percentage: -1, material_cost: -1 } }

  describe "GET /index" do
    it "renders a successful response" do
      create(:nut_bolt_washer_rate)
      sign_in user
      get nut_bolt_washer_rates_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      nut_bolt_washer_rate = create(:nut_bolt_washer_rate)
      sign_in user
      get nut_bolt_washer_rate_url(nut_bolt_washer_rate)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    context "as admin" do
      it "renders a successful response" do
        sign_in admin
        get new_nut_bolt_washer_rate_url
        expect(response).to be_successful
      end
    end

    context "as non-admin" do
      it "redirects to the root path" do
        sign_in user
        get new_nut_bolt_washer_rate_url
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /create" do
    context "as admin" do
      before { sign_in admin }

      context "with valid parameters" do
        it "creates a new NutBoltWasherRate" do
          expect {
            post nut_bolt_washer_rates_url, params: { nut_bolt_washer_rate: valid_attributes }
          }.to change(NutBoltWasherRate, :count).by(1)
        end

        it "redirects to the created nut_bolt_washer_rate" do
          post nut_bolt_washer_rates_url, params: { nut_bolt_washer_rate: valid_attributes }
          expect(response).to redirect_to(nut_bolt_washer_rate_url(NutBoltWasherRate.last))
        end
      end

      context "with invalid parameters" do
        it "does not create a new NutBoltWasherRate" do
          expect {
            post nut_bolt_washer_rates_url, params: { nut_bolt_washer_rate: invalid_attributes }
          }.to change(NutBoltWasherRate, :count).by(0)
        end

        it "renders a response with 422 status" do
          post nut_bolt_washer_rates_url, params: { nut_bolt_washer_rate: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "as non-admin" do
      it "does not create a new NutBoltWasherRate" do
        sign_in user
        expect {
          post nut_bolt_washer_rates_url, params: { nut_bolt_washer_rate: valid_attributes }
        }.to change(NutBoltWasherRate, :count).by(0)
      end
    end
  end

  describe "PATCH /update" do
    let(:nut_bolt_washer_rate) { create(:nut_bolt_washer_rate) }

    context "as admin" do
      before { sign_in admin }

      context "with valid parameters" do
        let(:new_attributes) { { name: 'Updated Name', calculation_breakdown: 'Updated breakdown', mass_per_each: 0.456 } }

        it "updates the requested nut_bolt_washer_rate" do
          patch nut_bolt_washer_rate_url(nut_bolt_washer_rate), params: { nut_bolt_washer_rate: new_attributes }
          nut_bolt_washer_rate.reload
          expect(nut_bolt_washer_rate.name).to eq('Updated Name')
          expect(nut_bolt_washer_rate.calculation_breakdown).to eq('Updated breakdown')
          expect(nut_bolt_washer_rate.mass_per_each).to eq(0.456)
        end

        it "redirects to the nut_bolt_washer_rate" do
          patch nut_bolt_washer_rate_url(nut_bolt_washer_rate), params: { nut_bolt_washer_rate: new_attributes }
          expect(response).to redirect_to(nut_bolt_washer_rate_url(nut_bolt_washer_rate))
        end
      end

      context "with invalid parameters" do
        it "renders a response with 422 status" do
          patch nut_bolt_washer_rate_url(nut_bolt_washer_rate), params: { nut_bolt_washer_rate: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "as non-admin" do
      it "does not update the requested nut_bolt_washer_rate" do
        sign_in user
        patch nut_bolt_washer_rate_url(nut_bolt_washer_rate), params: { nut_bolt_washer_rate: { name: 'Unauthorized Update' } }
        nut_bolt_washer_rate.reload
        expect(nut_bolt_washer_rate.name).not_to eq('Unauthorized Update')
      end
    end
  end

  describe "DELETE /destroy" do
    let!(:nut_bolt_washer_rate) { create(:nut_bolt_washer_rate) }

    context "as admin" do
      before { sign_in admin }

      it "destroys the requested nut_bolt_washer_rate" do
        expect {
          delete nut_bolt_washer_rate_url(nut_bolt_washer_rate)
        }.to change(NutBoltWasherRate, :count).by(-1)
      end

      it "redirects to the nut_bolt_washer_rates list" do
        delete nut_bolt_washer_rate_url(nut_bolt_washer_rate)
        expect(response).to redirect_to(nut_bolt_washer_rates_url)
      end
    end

    context "as non-admin" do
      it "does not destroy the requested nut_bolt_washer_rate" do
        sign_in user
        expect {
          delete nut_bolt_washer_rate_url(nut_bolt_washer_rate)
        }.to change(NutBoltWasherRate, :count).by(0)
      end
    end
  end

  describe "PATCH /reorder" do
    let!(:rate1) { create(:nut_bolt_washer_rate, position: 1) }
    let!(:rate2) { create(:nut_bolt_washer_rate, position: 2) }

    context "as admin" do
      before { sign_in admin }

      it "reorders the rates" do
        patch reorder_nut_bolt_washer_rates_url, params: { ids: [rate2.id, rate1.id] }
        expect(response).to have_http_status(:ok)
        expect(rate1.reload.position).to eq(2)
        expect(rate2.reload.position).to eq(1)
      end
    end

    context "as non-admin" do
      it "returns unauthorized" do
        sign_in user
        patch reorder_nut_bolt_washer_rates_url, params: { ids: [rate2.id, rate1.id] }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
