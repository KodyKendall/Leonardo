require "rails_helper"

RSpec.describe NutBoltWasherRatesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/nut_bolt_washer_rates").to route_to("nut_bolt_washer_rates#index")
    end

    it "routes to #new" do
      expect(get: "/nut_bolt_washer_rates/new").to route_to("nut_bolt_washer_rates#new")
    end

    it "routes to #show" do
      expect(get: "/nut_bolt_washer_rates/1").to route_to("nut_bolt_washer_rates#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/nut_bolt_washer_rates/1/edit").to route_to("nut_bolt_washer_rates#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/nut_bolt_washer_rates").to route_to("nut_bolt_washer_rates#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/nut_bolt_washer_rates/1").to route_to("nut_bolt_washer_rates#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/nut_bolt_washer_rates/1").to route_to("nut_bolt_washer_rates#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/nut_bolt_washer_rates/1").to route_to("nut_bolt_washer_rates#destroy", id: "1")
    end
  end
end
