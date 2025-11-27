require "rails_helper"

RSpec.describe LineItemMaterialsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/line_item_materials").to route_to("line_item_materials#index")
    end

    it "routes to #new" do
      expect(get: "/line_item_materials/new").to route_to("line_item_materials#new")
    end

    it "routes to #show" do
      expect(get: "/line_item_materials/1").to route_to("line_item_materials#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/line_item_materials/1/edit").to route_to("line_item_materials#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/line_item_materials").to route_to("line_item_materials#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/line_item_materials/1").to route_to("line_item_materials#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/line_item_materials/1").to route_to("line_item_materials#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/line_item_materials/1").to route_to("line_item_materials#destroy", id: "1")
    end
  end
end
