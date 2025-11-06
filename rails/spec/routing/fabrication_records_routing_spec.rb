require "rails_helper"

RSpec.describe FabricationRecordsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/fabrication_records").to route_to("fabrication_records#index")
    end

    it "routes to #new" do
      expect(get: "/fabrication_records/new").to route_to("fabrication_records#new")
    end

    it "routes to #show" do
      expect(get: "/fabrication_records/1").to route_to("fabrication_records#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/fabrication_records/1/edit").to route_to("fabrication_records#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/fabrication_records").to route_to("fabrication_records#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/fabrication_records/1").to route_to("fabrication_records#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/fabrication_records/1").to route_to("fabrication_records#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/fabrication_records/1").to route_to("fabrication_records#destroy", id: "1")
    end
  end
end
