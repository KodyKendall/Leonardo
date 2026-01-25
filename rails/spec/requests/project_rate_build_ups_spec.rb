require 'rails_helper'

# ProjectRateBuildUp is nested under tenders with only show, edit, update actions
# Routes: GET/PATCH /tenders/:tender_id/project_rate_build_ups/:id

RSpec.describe "/tenders/:tender_id/project_rate_build_ups", type: :request do
  let(:user) { create(:user) }
  let(:tender) { create(:tender) }
  # Tender's after_create callback automatically creates project_rate_buildup
  # Force reload to ensure the association is loaded
  let(:project_rate_build_up) { tender.reload.project_rate_buildup }

  before { sign_in user }

  describe "GET /show" do
    it "renders a successful response" do
      get tender_project_rate_build_up_path(tender, project_rate_build_up)
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      get edit_tender_project_rate_build_up_path(tender, project_rate_build_up)
      expect(response).to be_successful
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        { profit_margin_percentage: 15.0, fabrication_rate: 100.0, delivery_rate_note: "Bulk delivery discount" }
      }

      it "updates the requested project_rate_build_up" do
        patch tender_project_rate_build_up_path(tender, project_rate_build_up), params: { project_rate_build_up: new_attributes }
        project_rate_build_up.reload
        expect(project_rate_build_up.profit_margin_percentage).to eq(15.0)
        expect(project_rate_build_up.fabrication_rate).to eq(100.0)
        expect(project_rate_build_up.delivery_rate_note).to eq("Bulk delivery discount")
      end

      it "redirects to the tender" do
        patch tender_project_rate_build_up_path(tender, project_rate_build_up), params: { project_rate_build_up: new_attributes }
        expect(response).to redirect_to(tender_path(tender))
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) {
        { profit_margin_percentage: -10.0 }
      }

      it "renders a response with 422 status" do
        patch tender_project_rate_build_up_path(tender, project_rate_build_up), params: { project_rate_build_up: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
