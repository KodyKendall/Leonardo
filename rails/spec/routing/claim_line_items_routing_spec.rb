require "rails_helper"

RSpec.describe ClaimLineItemsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/claim_line_items").to route_to("claim_line_items#index")
    end

    it "routes to #new" do
      expect(get: "/claim_line_items/new").to route_to("claim_line_items#new")
    end

    it "routes to #show" do
      expect(get: "/claim_line_items/1").to route_to("claim_line_items#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/claim_line_items/1/edit").to route_to("claim_line_items#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/claim_line_items").to route_to("claim_line_items#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/claim_line_items/1").to route_to("claim_line_items#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/claim_line_items/1").to route_to("claim_line_items#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/claim_line_items/1").to route_to("claim_line_items#destroy", id: "1")
    end
  end
end
