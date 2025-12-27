require "rails_helper"

RSpec.describe TenderEquipmentSelectionsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/tender_equipment_selections").to route_to("tender_equipment_selections#index")
    end

    it "routes to #new" do
      expect(get: "/tender_equipment_selections/new").to route_to("tender_equipment_selections#new")
    end

    it "routes to #show" do
      expect(get: "/tender_equipment_selections/1").to route_to("tender_equipment_selections#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/tender_equipment_selections/1/edit").to route_to("tender_equipment_selections#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/tender_equipment_selections").to route_to("tender_equipment_selections#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/tender_equipment_selections/1").to route_to("tender_equipment_selections#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/tender_equipment_selections/1").to route_to("tender_equipment_selections#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/tender_equipment_selections/1").to route_to("tender_equipment_selections#destroy", id: "1")
    end
  end
end
