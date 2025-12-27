require 'rails_helper'

RSpec.describe "project_rate_build_ups/edit", type: :view do
  let(:project_rate_build_up) {
    ProjectRateBuildUp.create!(
      tender: nil,
      material_supply_rate: "9.99",
      fabrication_rate: "9.99",
      overheads_rate: "9.99",
      shop_priming_rate: "9.99",
      onsite_painting_rate: "9.99",
      delivery_rate: "9.99",
      bolts_rate: "9.99",
      erection_rate: "9.99",
      crainage_rate: "9.99",
      cherry_picker_rate: "9.99",
      galvanizing_rate: "9.99"
    )
  }

  before(:each) do
    assign(:project_rate_build_up, project_rate_build_up)
  end

  it "renders the edit project_rate_build_up form" do
    render

    assert_select "form[action=?][method=?]", project_rate_build_up_path(project_rate_build_up), "post" do

      assert_select "input[name=?]", "project_rate_build_up[tender_id]"

      assert_select "input[name=?]", "project_rate_build_up[material_supply_rate]"

      assert_select "input[name=?]", "project_rate_build_up[fabrication_rate]"

      assert_select "input[name=?]", "project_rate_build_up[overheads_rate]"

      assert_select "input[name=?]", "project_rate_build_up[shop_priming_rate]"

      assert_select "input[name=?]", "project_rate_build_up[onsite_painting_rate]"

      assert_select "input[name=?]", "project_rate_build_up[delivery_rate]"

      assert_select "input[name=?]", "project_rate_build_up[bolts_rate]"

      assert_select "input[name=?]", "project_rate_build_up[erection_rate]"

      assert_select "input[name=?]", "project_rate_build_up[crainage_rate]"

      assert_select "input[name=?]", "project_rate_build_up[cherry_picker_rate]"

      assert_select "input[name=?]", "project_rate_build_up[galvanizing_rate]"
    end
  end
end
