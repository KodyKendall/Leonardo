require 'rails_helper'

RSpec.describe "/section_categories", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  let(:valid_attributes) {
    { name: 'test_category', display_name: 'Test Category' }
  }

  let(:invalid_attributes) {
    { name: '', display_name: '' }
  }

  describe "GET /index" do
    it "renders a successful response" do
      sign_in admin_user
      create(:section_category)
      get section_categories_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      sign_in admin_user
      section_category = create(:section_category)
      get section_category_url(section_category)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response for admin users" do
      sign_in admin_user
      get new_section_category_url
      expect(response).to be_successful
    end

    it "redirects non-admin users" do
      sign_in regular_user
      get new_section_category_url
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /edit" do
    it "renders a successful response for admin users" do
      sign_in admin_user
      section_category = create(:section_category)
      get edit_section_category_url(section_category)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new SectionCategory" do
        sign_in admin_user
        expect {
          post section_categories_url, params: { section_category: valid_attributes }
        }.to change(SectionCategory, :count).by(1)
      end

      it "redirects to the created section_category" do
        sign_in admin_user
        post section_categories_url, params: { section_category: valid_attributes }
        expect(response).to redirect_to(section_category_url(SectionCategory.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new SectionCategory" do
        sign_in admin_user
        expect {
          post section_categories_url, params: { section_category: invalid_attributes }
        }.to change(SectionCategory, :count).by(0)
      end

      it "renders a response with 422 status" do
        sign_in admin_user
        post section_categories_url, params: { section_category: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "for non-admin users" do
      it "redirects to root" do
        sign_in regular_user
        post section_categories_url, params: { section_category: valid_attributes }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        { display_name: 'Updated Category Name' }
      }

      it "updates the requested section_category" do
        sign_in admin_user
        section_category = create(:section_category)
        patch section_category_url(section_category), params: { section_category: new_attributes }
        section_category.reload
        expect(section_category.display_name).to eq('Updated Category Name')
      end

      it "redirects to the section_category" do
        sign_in admin_user
        section_category = create(:section_category)
        patch section_category_url(section_category), params: { section_category: new_attributes }
        expect(response).to redirect_to(section_category_url(section_category))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status" do
        sign_in admin_user
        section_category = create(:section_category)
        patch section_category_url(section_category), params: { section_category: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested section_category" do
      sign_in admin_user
      section_category = create(:section_category)
      expect {
        delete section_category_url(section_category)
      }.to change(SectionCategory, :count).by(-1)
    end

    it "redirects to the section_categories list" do
      sign_in admin_user
      section_category = create(:section_category)
      delete section_category_url(section_category)
      expect(response).to redirect_to(section_categories_url)
    end
  end
end
