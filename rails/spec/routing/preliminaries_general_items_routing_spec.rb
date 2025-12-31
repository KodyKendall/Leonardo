require "rails_helper"

RSpec.describe PreliminariesGeneralItemsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/preliminaries_general_items").to route_to("preliminaries_general_items#index")
    end

    it "routes to #new" do
      expect(get: "/preliminaries_general_items/new").to route_to("preliminaries_general_items#new")
    end

    it "routes to #show" do
      expect(get: "/preliminaries_general_items/1").to route_to("preliminaries_general_items#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/preliminaries_general_items/1/edit").to route_to("preliminaries_general_items#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/preliminaries_general_items").to route_to("preliminaries_general_items#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/preliminaries_general_items/1").to route_to("preliminaries_general_items#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/preliminaries_general_items/1").to route_to("preliminaries_general_items#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/preliminaries_general_items/1").to route_to("preliminaries_general_items#destroy", id: "1")
    end
  end
end
