require "rails_helper"

RSpec.describe CraneComplementsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/crane_complements").to route_to("crane_complements#index")
    end

    it "routes to #new" do
      expect(get: "/crane_complements/new").to route_to("crane_complements#new")
    end

    it "routes to #show" do
      expect(get: "/crane_complements/1").to route_to("crane_complements#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/crane_complements/1/edit").to route_to("crane_complements#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/crane_complements").to route_to("crane_complements#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/crane_complements/1").to route_to("crane_complements#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/crane_complements/1").to route_to("crane_complements#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/crane_complements/1").to route_to("crane_complements#destroy", id: "1")
    end
  end
end
