require "rails_helper"

RSpec.describe LineItemMaterialBreakdownsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/line_item_material_breakdowns").to route_to("line_item_material_breakdowns#index")
    end

    it "routes to #new" do
      expect(get: "/line_item_material_breakdowns/new").to route_to("line_item_material_breakdowns#new")
    end

    it "routes to #show" do
      expect(get: "/line_item_material_breakdowns/1").to route_to("line_item_material_breakdowns#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/line_item_material_breakdowns/1/edit").to route_to("line_item_material_breakdowns#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/line_item_material_breakdowns").to route_to("line_item_material_breakdowns#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/line_item_material_breakdowns/1").to route_to("line_item_material_breakdowns#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/line_item_material_breakdowns/1").to route_to("line_item_material_breakdowns#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/line_item_material_breakdowns/1").to route_to("line_item_material_breakdowns#destroy", id: "1")
    end
  end
end
