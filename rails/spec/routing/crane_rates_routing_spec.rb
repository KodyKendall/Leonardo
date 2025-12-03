require "rails_helper"

RSpec.describe CraneRatesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/crane_rates").to route_to("crane_rates#index")
    end

    it "routes to #new" do
      expect(get: "/crane_rates/new").to route_to("crane_rates#new")
    end

    it "routes to #show" do
      expect(get: "/crane_rates/1").to route_to("crane_rates#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/crane_rates/1/edit").to route_to("crane_rates#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/crane_rates").to route_to("crane_rates#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/crane_rates/1").to route_to("crane_rates#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/crane_rates/1").to route_to("crane_rates#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/crane_rates/1").to route_to("crane_rates#destroy", id: "1")
    end
  end
end
