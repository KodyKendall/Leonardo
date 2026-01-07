require 'rails_helper'

RSpec.describe "/tender_equipment_summaries", type: :request do
  let(:user) { create(:user) }
  let(:tender) { create(:tender) }

  let(:valid_attributes) {
    { tender_id: tender.id, establishment_cost: 5000.0, equipment_subtotal: 10000.0, mobilization_fee: 1000.0, total_equipment_cost: 16000.0 }
  }

  let(:invalid_attributes) {
    { tender_id: nil, equipment_subtotal: -1000, mobilization_fee: -1000, total_equipment_cost: -1000 }
  }

  before { sign_in user }

  describe "GET /index" do
    it "renders a successful response" do
      create(:tender_equipment_summary, tender: tender)
      get tender_equipment_summaries_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      summary = create(:tender_equipment_summary, tender: tender)
      get tender_equipment_summary_url(summary)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_tender_equipment_summary_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      summary = create(:tender_equipment_summary, tender: tender)
      get edit_tender_equipment_summary_url(summary)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new TenderEquipmentSummary" do
        new_tender = create(:tender)
        expect {
          post tender_equipment_summaries_url, params: { tender_equipment_summary: { tender_id: new_tender.id, establishment_cost: 5000.0, equipment_subtotal: 10000.0, mobilization_fee: 1000.0, total_equipment_cost: 16000.0 } }
        }.to change(TenderEquipmentSummary, :count).by(1)
      end

      it "redirects to the created summary" do
        new_tender = create(:tender)
        post tender_equipment_summaries_url, params: { tender_equipment_summary: { tender_id: new_tender.id, establishment_cost: 5000.0, equipment_subtotal: 10000.0, mobilization_fee: 1000.0, total_equipment_cost: 16000.0 } }
        expect(response).to redirect_to(tender_equipment_summary_url(TenderEquipmentSummary.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new TenderEquipmentSummary" do
        expect {
          post tender_equipment_summaries_url, params: { tender_equipment_summary: invalid_attributes }
        }.to change(TenderEquipmentSummary, :count).by(0)
      end

      it "renders a response with 422 status" do
        post tender_equipment_summaries_url, params: { tender_equipment_summary: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        { establishment_cost: 10000.0 }
      }

      it "updates the requested summary" do
        summary = create(:tender_equipment_summary, tender: tender)
        patch tender_equipment_summary_url(summary), params: { tender_equipment_summary: new_attributes }
        summary.reload
        expect(summary.establishment_cost).to eq(10000.0)
      end

      it "redirects to the summary" do
        summary = create(:tender_equipment_summary, tender: tender)
        patch tender_equipment_summary_url(summary), params: { tender_equipment_summary: new_attributes }
        expect(response).to redirect_to(tender_equipment_summary_url(summary))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status" do
        summary = create(:tender_equipment_summary, tender: tender)
        patch tender_equipment_summary_url(summary), params: { tender_equipment_summary: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested summary" do
      summary = create(:tender_equipment_summary, tender: tender)
      expect {
        delete tender_equipment_summary_url(summary)
      }.to change(TenderEquipmentSummary, :count).by(-1)
    end

    it "redirects to the summaries list" do
      summary = create(:tender_equipment_summary, tender: tender)
      delete tender_equipment_summary_url(summary)
      expect(response).to redirect_to(tender_equipment_summaries_url)
    end
  end
end
