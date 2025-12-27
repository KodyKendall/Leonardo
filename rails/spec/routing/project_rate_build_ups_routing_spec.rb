require "rails_helper"

RSpec.describe ProjectRateBuildUpsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/project_rate_build_ups").to route_to("project_rate_build_ups#index")
    end

    it "routes to #new" do
      expect(get: "/project_rate_build_ups/new").to route_to("project_rate_build_ups#new")
    end

    it "routes to #show" do
      expect(get: "/project_rate_build_ups/1").to route_to("project_rate_build_ups#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/project_rate_build_ups/1/edit").to route_to("project_rate_build_ups#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/project_rate_build_ups").to route_to("project_rate_build_ups#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/project_rate_build_ups/1").to route_to("project_rate_build_ups#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/project_rate_build_ups/1").to route_to("project_rate_build_ups#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/project_rate_build_ups/1").to route_to("project_rate_build_ups#destroy", id: "1")
    end
  end
end
