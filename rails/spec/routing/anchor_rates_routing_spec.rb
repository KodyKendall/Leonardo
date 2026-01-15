require "rails_helper"

RSpec.describe AnchorRatesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/anchor_rates").to route_to("anchor_rates#index")
    end

    it "routes to #new" do
      expect(get: "/anchor_rates/new").to route_to("anchor_rates#new")
    end

    it "routes to #show" do
      expect(get: "/anchor_rates/1").to route_to("anchor_rates#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/anchor_rates/1/edit").to route_to("anchor_rates#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/anchor_rates").to route_to("anchor_rates#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/anchor_rates/1").to route_to("anchor_rates#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/anchor_rates/1").to route_to("anchor_rates#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/anchor_rates/1").to route_to("anchor_rates#destroy", id: "1")
    end
  end
end
