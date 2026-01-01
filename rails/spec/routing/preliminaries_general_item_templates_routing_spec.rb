require "rails_helper"

RSpec.describe PreliminariesGeneralItemTemplatesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/preliminaries_general_item_templates").to route_to("preliminaries_general_item_templates#index")
    end

    it "routes to #new" do
      expect(get: "/preliminaries_general_item_templates/new").to route_to("preliminaries_general_item_templates#new")
    end

    it "routes to #show" do
      expect(get: "/preliminaries_general_item_templates/1").to route_to("preliminaries_general_item_templates#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/preliminaries_general_item_templates/1/edit").to route_to("preliminaries_general_item_templates#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/preliminaries_general_item_templates").to route_to("preliminaries_general_item_templates#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/preliminaries_general_item_templates/1").to route_to("preliminaries_general_item_templates#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/preliminaries_general_item_templates/1").to route_to("preliminaries_general_item_templates#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/preliminaries_general_item_templates/1").to route_to("preliminaries_general_item_templates#destroy", id: "1")
    end
  end
end
