require 'rails_helper'

# PreliminariesGeneralItemTemplate routes are at /p_and_g_templates
RSpec.describe "/p_and_g_templates", type: :request do
  let(:user) { create(:user) }

  let(:valid_attributes) {
    { category: 'fixed', description: 'Test Template', quantity: 1, rate: 100.0 }
  }

  let(:invalid_attributes) {
    { category: '', description: '', quantity: -1, rate: -10 }
  }

  before { sign_in user }

  describe "GET /index" do
    it "renders a successful response" do
      create(:preliminaries_general_item_template)
      get preliminaries_general_item_templates_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      template = create(:preliminaries_general_item_template)
      get preliminaries_general_item_template_url(template)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_preliminaries_general_item_template_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      template = create(:preliminaries_general_item_template)
      get edit_preliminaries_general_item_template_url(template)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new PreliminariesGeneralItemTemplate" do
        expect {
          post preliminaries_general_item_templates_url, params: { preliminaries_general_item_template: valid_attributes }
        }.to change(PreliminariesGeneralItemTemplate, :count).by(1)
      end

      it "redirects to the created template" do
        post preliminaries_general_item_templates_url, params: { preliminaries_general_item_template: valid_attributes }
        expect(response).to redirect_to(preliminaries_general_item_template_url(PreliminariesGeneralItemTemplate.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new PreliminariesGeneralItemTemplate" do
        expect {
          post preliminaries_general_item_templates_url, params: { preliminaries_general_item_template: invalid_attributes }
        }.to change(PreliminariesGeneralItemTemplate, :count).by(0)
      end

      it "renders a response with 422 status" do
        post preliminaries_general_item_templates_url, params: { preliminaries_general_item_template: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        { description: 'Updated Template Description' }
      }

      it "updates the requested template" do
        template = create(:preliminaries_general_item_template)
        patch preliminaries_general_item_template_url(template), params: { preliminaries_general_item_template: new_attributes }
        template.reload
        expect(template.description).to eq('Updated Template Description')
      end

      it "redirects to the template" do
        template = create(:preliminaries_general_item_template)
        patch preliminaries_general_item_template_url(template), params: { preliminaries_general_item_template: new_attributes }
        expect(response).to redirect_to(preliminaries_general_item_template_url(template))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status" do
        template = create(:preliminaries_general_item_template)
        patch preliminaries_general_item_template_url(template), params: { preliminaries_general_item_template: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested template" do
      template = create(:preliminaries_general_item_template)
      expect {
        delete preliminaries_general_item_template_url(template)
      }.to change(PreliminariesGeneralItemTemplate, :count).by(-1)
    end

    it "redirects to the templates list" do
      template = create(:preliminaries_general_item_template)
      delete preliminaries_general_item_template_url(template)
      expect(response).to redirect_to(preliminaries_general_item_templates_url)
    end
  end
end
