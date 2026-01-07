require 'rails_helper'

# PreliminariesGeneralItem is nested under tenders with path 'p_and_g'
# Routes: /tenders/:tender_id/p_and_g

RSpec.describe "/tenders/:tender_id/p_and_g", type: :request do
  let(:user) { create(:user) }
  let(:tender) { create(:tender) }

  let(:valid_attributes) {
    { category: 'fixed_based', description: 'Test P&G Item', quantity: 10, rate: 100.0 }
  }

  let(:invalid_attributes) {
    { category: 'fixed_based', description: '', quantity: 0, rate: -10 }
  }

  before { sign_in user }

  describe "GET /index" do
    it "renders a successful response" do
      create(:preliminaries_general_item, tender: tender)
      get tender_preliminaries_general_items_path(tender)
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "redirects to index" do
      item = create(:preliminaries_general_item, tender: tender)
      get tender_preliminaries_general_item_path(tender, item)
      expect(response).to redirect_to(tender_preliminaries_general_items_path(tender))
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_tender_preliminaries_general_item_path(tender)
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      item = create(:preliminaries_general_item, tender: tender)
      get edit_tender_preliminaries_general_item_path(tender, item)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new PreliminariesGeneralItem" do
        expect {
          post tender_preliminaries_general_items_path(tender), params: { preliminaries_general_item: valid_attributes }
        }.to change(PreliminariesGeneralItem, :count).by(1)
      end

      it "redirects to the index" do
        post tender_preliminaries_general_items_path(tender), params: { preliminaries_general_item: valid_attributes }
        expect(response).to redirect_to(tender_preliminaries_general_items_path(tender))
      end
    end

    context "with invalid parameters" do
      it "does not create a new PreliminariesGeneralItem" do
        expect {
          post tender_preliminaries_general_items_path(tender), params: { preliminaries_general_item: invalid_attributes }
        }.to change(PreliminariesGeneralItem, :count).by(0)
      end

      it "renders a response with 422 status" do
        post tender_preliminaries_general_items_path(tender), params: { preliminaries_general_item: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        { description: 'Updated Description', rate: 200.0 }
      }

      it "updates the requested item" do
        item = create(:preliminaries_general_item, tender: tender)
        patch tender_preliminaries_general_item_path(tender, item), params: { preliminaries_general_item: new_attributes }
        item.reload
        expect(item.description).to eq('Updated Description')
        expect(item.rate).to eq(200.0)
      end

      it "redirects to the index" do
        item = create(:preliminaries_general_item, tender: tender)
        patch tender_preliminaries_general_item_path(tender, item), params: { preliminaries_general_item: new_attributes }
        expect(response).to redirect_to(tender_preliminaries_general_items_path(tender))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status" do
        item = create(:preliminaries_general_item, tender: tender)
        patch tender_preliminaries_general_item_path(tender, item), params: { preliminaries_general_item: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested item" do
      item = create(:preliminaries_general_item, tender: tender)
      expect {
        delete tender_preliminaries_general_item_path(tender, item)
      }.to change(PreliminariesGeneralItem, :count).by(-1)
    end

    it "redirects to the index" do
      item = create(:preliminaries_general_item, tender: tender)
      delete tender_preliminaries_general_item_path(tender, item)
      expect(response).to redirect_to(tender_preliminaries_general_items_path(tender))
    end
  end

  describe "GET /totals" do
    it "renders the totals partial" do
      get totals_tender_preliminaries_general_items_path(tender)
      expect(response).to be_successful
    end
  end
end
