require 'rails_helper'

# TenderEquipmentSelection is nested under tenders as 'equipment_selections'
# Routes: /tenders/:tender_id/equipment_selections
# Controller: EquipmentSelectionsController
# Only has: index, create, update, destroy (no show, new, edit)

RSpec.describe "/tenders/:tender_id/equipment_selections", type: :request do
  let(:user) { create(:user) }
  let(:tender) { create(:tender) }
  let(:equipment_type) { create(:equipment_type) }

  let(:valid_attributes) {
    { equipment_type_id: equipment_type.id, units_required: 2, period_months: 6 }
  }

  let(:invalid_attributes) {
    { equipment_type_id: nil, units_required: -1, period_months: 0 }
  }

  before do
    sign_in user
    # Ensure tender has an equipment summary with required fields (required by the view)
    unless tender.tender_equipment_summary
      create(:tender_equipment_summary, tender: tender)
    end
  end

  describe "GET /index" do
    it "renders a successful response" do
      create(:tender_equipment_selection, tender: tender, equipment_type: equipment_type)
      get tender_equipment_selections_path(tender)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new TenderEquipmentSelection" do
        expect {
          post tender_equipment_selections_path(tender), params: { tender_equipment_selection: valid_attributes }
        }.to change(TenderEquipmentSelection, :count).by(1)
      end

      it "redirects to the index" do
        post tender_equipment_selections_path(tender), params: { tender_equipment_selection: valid_attributes }
        expect(response).to redirect_to(tender_equipment_selections_path(tender))
      end

      it "creates a selection with decimal period_months" do
        decimal_attributes = valid_attributes.merge(period_months: 1.5)
        expect {
          post tender_equipment_selections_path(tender), params: { tender_equipment_selection: decimal_attributes }
        }.to change(TenderEquipmentSelection, :count).by(1)
        expect(TenderEquipmentSelection.last.period_months).to eq(1.5)
      end
    end

    context "with invalid parameters" do
      it "does not create a new TenderEquipmentSelection" do
        expect {
          post tender_equipment_selections_path(tender), params: { tender_equipment_selection: invalid_attributes }
        }.to change(TenderEquipmentSelection, :count).by(0)
      end

      it "renders a response with 422 status" do
        post tender_equipment_selections_path(tender), params: { tender_equipment_selection: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        { units_required: 5, period_months: 12 }
      }

      it "updates the requested equipment selection" do
        selection = create(:tender_equipment_selection, tender: tender, equipment_type: equipment_type)
        patch tender_equipment_selection_path(tender, selection), params: { tender_equipment_selection: new_attributes }
        selection.reload
        expect(selection.units_required).to eq(5)
        expect(selection.period_months).to eq(12)
      end

      it "redirects to the index" do
        selection = create(:tender_equipment_selection, tender: tender, equipment_type: equipment_type)
        patch tender_equipment_selection_path(tender, selection), params: { tender_equipment_selection: new_attributes }
        expect(response).to redirect_to(tender_equipment_selections_path(tender))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status" do
        selection = create(:tender_equipment_selection, tender: tender, equipment_type: equipment_type)
        patch tender_equipment_selection_path(tender, selection), params: { tender_equipment_selection: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested equipment selection" do
      selection = create(:tender_equipment_selection, tender: tender, equipment_type: equipment_type)
      expect {
        delete tender_equipment_selection_path(tender, selection)
      }.to change(TenderEquipmentSelection, :count).by(-1)
    end

    it "redirects to the index" do
      selection = create(:tender_equipment_selection, tender: tender, equipment_type: equipment_type)
      delete tender_equipment_selection_path(tender, selection)
      expect(response).to redirect_to(tender_equipment_selections_path(tender))
    end
  end
end
