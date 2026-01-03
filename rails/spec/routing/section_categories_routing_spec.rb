require "rails_helper"

RSpec.describe SectionCategoriesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/section_categories").to route_to("section_categories#index")
    end

    it "routes to #new" do
      expect(get: "/section_categories/new").to route_to("section_categories#new")
    end

    it "routes to #show" do
      expect(get: "/section_categories/1").to route_to("section_categories#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/section_categories/1/edit").to route_to("section_categories#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/section_categories").to route_to("section_categories#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/section_categories/1").to route_to("section_categories#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/section_categories/1").to route_to("section_categories#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/section_categories/1").to route_to("section_categories#destroy", id: "1")
    end
  end
end
