require "rails_helper"

RSpec.describe MonthlyMaterialSupplyRatesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/monthly_material_supply_rates").to route_to("monthly_material_supply_rates#index")
    end

    it "routes to #new" do
      expect(get: "/monthly_material_supply_rates/new").to route_to("monthly_material_supply_rates#new")
    end

    it "routes to #show" do
      expect(get: "/monthly_material_supply_rates/1").to route_to("monthly_material_supply_rates#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/monthly_material_supply_rates/1/edit").to route_to("monthly_material_supply_rates#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/monthly_material_supply_rates").to route_to("monthly_material_supply_rates#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/monthly_material_supply_rates/1").to route_to("monthly_material_supply_rates#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/monthly_material_supply_rates/1").to route_to("monthly_material_supply_rates#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/monthly_material_supply_rates/1").to route_to("monthly_material_supply_rates#destroy", id: "1")
    end
  end
end
