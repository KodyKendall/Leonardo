require "rails_helper"

RSpec.describe OnSiteMobileCraneBreakdownsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/on_site_mobile_crane_breakdowns").to route_to("on_site_mobile_crane_breakdowns#index")
    end

    it "routes to #new" do
      expect(get: "/on_site_mobile_crane_breakdowns/new").to route_to("on_site_mobile_crane_breakdowns#new")
    end

    it "routes to #show" do
      expect(get: "/on_site_mobile_crane_breakdowns/1").to route_to("on_site_mobile_crane_breakdowns#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/on_site_mobile_crane_breakdowns/1/edit").to route_to("on_site_mobile_crane_breakdowns#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/on_site_mobile_crane_breakdowns").to route_to("on_site_mobile_crane_breakdowns#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/on_site_mobile_crane_breakdowns/1").to route_to("on_site_mobile_crane_breakdowns#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/on_site_mobile_crane_breakdowns/1").to route_to("on_site_mobile_crane_breakdowns#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/on_site_mobile_crane_breakdowns/1").to route_to("on_site_mobile_crane_breakdowns#destroy", id: "1")
    end
  end
end
