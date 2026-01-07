require 'rails_helper'

RSpec.describe "/equipment_types", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  let(:valid_attributes) {
    { category: 'diesel_boom', model: 'Test Model', working_height_m: 20.0, base_rate_monthly: 5000.0, damage_waiver_pct: 0.1, diesel_allowance_monthly: 500.0 }
  }

  let(:invalid_attributes) {
    { category: '', model: '', base_rate_monthly: nil, damage_waiver_pct: nil, diesel_allowance_monthly: nil }
  }

  describe "GET /index" do
    it "renders a successful response" do
      sign_in admin_user
      create(:equipment_type)
      get equipment_types_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      sign_in admin_user
      equipment_type = create(:equipment_type)
      get equipment_type_url(equipment_type)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response for admin users" do
      sign_in admin_user
      get new_equipment_type_url
      expect(response).to be_successful
    end

    it "redirects non-admin users" do
      sign_in regular_user
      get new_equipment_type_url
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /edit" do
    it "renders a successful response for admin users" do
      sign_in admin_user
      equipment_type = create(:equipment_type)
      get edit_equipment_type_url(equipment_type)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new EquipmentType" do
        sign_in admin_user
        expect {
          post equipment_types_url, params: { equipment_type: valid_attributes }
        }.to change(EquipmentType, :count).by(1)
      end

      it "redirects to the created equipment_type" do
        sign_in admin_user
        post equipment_types_url, params: { equipment_type: valid_attributes }
        expect(response).to redirect_to(equipment_type_url(EquipmentType.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new EquipmentType" do
        sign_in admin_user
        expect {
          post equipment_types_url, params: { equipment_type: invalid_attributes }
        }.to change(EquipmentType, :count).by(0)
      end

      it "renders a response with 422 status" do
        sign_in admin_user
        post equipment_types_url, params: { equipment_type: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "for non-admin users" do
      it "redirects to root" do
        sign_in regular_user
        post equipment_types_url, params: { equipment_type: valid_attributes }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        { model: 'Updated Model Name' }
      }

      it "updates the requested equipment_type" do
        sign_in admin_user
        equipment_type = create(:equipment_type)
        patch equipment_type_url(equipment_type), params: { equipment_type: new_attributes }
        equipment_type.reload
        expect(equipment_type.model).to eq('Updated Model Name')
      end

      it "redirects to the equipment_type" do
        sign_in admin_user
        equipment_type = create(:equipment_type)
        patch equipment_type_url(equipment_type), params: { equipment_type: new_attributes }
        expect(response).to redirect_to(equipment_type_url(equipment_type))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status" do
        sign_in admin_user
        equipment_type = create(:equipment_type)
        patch equipment_type_url(equipment_type), params: { equipment_type: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested equipment_type" do
      sign_in admin_user
      equipment_type = create(:equipment_type)
      expect {
        delete equipment_type_url(equipment_type)
      }.to change(EquipmentType, :count).by(-1)
    end

    it "redirects to the equipment_types list" do
      sign_in admin_user
      equipment_type = create(:equipment_type)
      delete equipment_type_url(equipment_type)
      expect(response).to redirect_to(equipment_types_url)
    end
  end
end
