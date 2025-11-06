require "rails_helper"

RSpec.describe VariationOrdersController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/variation_orders").to route_to("variation_orders#index")
    end

    it "routes to #new" do
      expect(get: "/variation_orders/new").to route_to("variation_orders#new")
    end

    it "routes to #show" do
      expect(get: "/variation_orders/1").to route_to("variation_orders#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/variation_orders/1/edit").to route_to("variation_orders#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/variation_orders").to route_to("variation_orders#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/variation_orders/1").to route_to("variation_orders#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/variation_orders/1").to route_to("variation_orders#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/variation_orders/1").to route_to("variation_orders#destroy", id: "1")
    end
  end
end
