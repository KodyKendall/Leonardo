require "rails_helper"

RSpec.describe TenderEquipmentSummariesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/tender_equipment_summaries").to route_to("tender_equipment_summaries#index")
    end

    it "routes to #new" do
      expect(get: "/tender_equipment_summaries/new").to route_to("tender_equipment_summaries#new")
    end

    it "routes to #show" do
      expect(get: "/tender_equipment_summaries/1").to route_to("tender_equipment_summaries#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/tender_equipment_summaries/1/edit").to route_to("tender_equipment_summaries#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/tender_equipment_summaries").to route_to("tender_equipment_summaries#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/tender_equipment_summaries/1").to route_to("tender_equipment_summaries#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/tender_equipment_summaries/1").to route_to("tender_equipment_summaries#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/tender_equipment_summaries/1").to route_to("tender_equipment_summaries#destroy", id: "1")
    end
  end
end
