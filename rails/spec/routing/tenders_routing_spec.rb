require "rails_helper"

RSpec.describe TendersController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/tenders").to route_to("tenders#index")
    end

    it "routes to #new" do
      expect(get: "/tenders/new").to route_to("tenders#new")
    end

    it "routes to #show" do
      expect(get: "/tenders/1").to route_to("tenders#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/tenders/1/edit").to route_to("tenders#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/tenders").to route_to("tenders#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/tenders/1").to route_to("tenders#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/tenders/1").to route_to("tenders#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/tenders/1").to route_to("tenders#destroy", id: "1")
    end
  end
end
