require "rails_helper"

RSpec.describe EquipmentTypesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/equipment_types").to route_to("equipment_types#index")
    end

    it "routes to #new" do
      expect(get: "/equipment_types/new").to route_to("equipment_types#new")
    end

    it "routes to #show" do
      expect(get: "/equipment_types/1").to route_to("equipment_types#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/equipment_types/1/edit").to route_to("equipment_types#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/equipment_types").to route_to("equipment_types#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/equipment_types/1").to route_to("equipment_types#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/equipment_types/1").to route_to("equipment_types#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/equipment_types/1").to route_to("equipment_types#destroy", id: "1")
    end
  end
end
