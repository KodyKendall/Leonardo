require "rails_helper"

RSpec.describe ClaimsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/claims").to route_to("claims#index")
    end

    it "routes to #new" do
      expect(get: "/claims/new").to route_to("claims#new")
    end

    it "routes to #show" do
      expect(get: "/claims/1").to route_to("claims#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/claims/1/edit").to route_to("claims#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/claims").to route_to("claims#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/claims/1").to route_to("claims#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/claims/1").to route_to("claims#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/claims/1").to route_to("claims#destroy", id: "1")
    end
  end
end
