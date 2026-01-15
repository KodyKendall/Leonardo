require "rails_helper"

RSpec.describe LineItemMaterialTemplatesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/line_item_material_templates").to route_to("line_item_material_templates#index")
    end

    it "routes to #new" do
      expect(get: "/line_item_material_templates/new").to route_to("line_item_material_templates#new")
    end

    it "routes to #show" do
      expect(get: "/line_item_material_templates/1").to route_to("line_item_material_templates#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/line_item_material_templates/1/edit").to route_to("line_item_material_templates#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/line_item_material_templates").to route_to("line_item_material_templates#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/line_item_material_templates/1").to route_to("line_item_material_templates#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/line_item_material_templates/1").to route_to("line_item_material_templates#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/line_item_material_templates/1").to route_to("line_item_material_templates#destroy", id: "1")
    end
  end
end
