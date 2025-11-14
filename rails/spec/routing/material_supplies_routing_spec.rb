require "rails_helper"

RSpec.describe MaterialSuppliesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/material_supplies").to route_to("material_supplies#index")
    end

    it "routes to #new" do
      expect(get: "/material_supplies/new").to route_to("material_supplies#new")
    end

    it "routes to #show" do
      expect(get: "/material_supplies/1").to route_to("material_supplies#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/material_supplies/1/edit").to route_to("material_supplies#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/material_supplies").to route_to("material_supplies#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/material_supplies/1").to route_to("material_supplies#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/material_supplies/1").to route_to("material_supplies#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/material_supplies/1").to route_to("material_supplies#destroy", id: "1")
    end
  end
end
