require "rails_helper"

RSpec.describe SectionCategoryTemplatesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/section_category_templates").to route_to("section_category_templates#index")
    end

    it "routes to #new" do
      expect(get: "/section_category_templates/new").to route_to("section_category_templates#new")
    end

    it "routes to #show" do
      expect(get: "/section_category_templates/1").to route_to("section_category_templates#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/section_category_templates/1/edit").to route_to("section_category_templates#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/section_category_templates").to route_to("section_category_templates#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/section_category_templates/1").to route_to("section_category_templates#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/section_category_templates/1").to route_to("section_category_templates#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/section_category_templates/1").to route_to("section_category_templates#destroy", id: "1")
    end
  end
end
