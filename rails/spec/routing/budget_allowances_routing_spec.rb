require "rails_helper"

RSpec.describe BudgetAllowancesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/budget_allowances").to route_to("budget_allowances#index")
    end

    it "routes to #new" do
      expect(get: "/budget_allowances/new").to route_to("budget_allowances#new")
    end

    it "routes to #show" do
      expect(get: "/budget_allowances/1").to route_to("budget_allowances#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/budget_allowances/1/edit").to route_to("budget_allowances#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/budget_allowances").to route_to("budget_allowances#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/budget_allowances/1").to route_to("budget_allowances#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/budget_allowances/1").to route_to("budget_allowances#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/budget_allowances/1").to route_to("budget_allowances#destroy", id: "1")
    end
  end
end
