require 'rails_helper'

RSpec.describe "project_rate_build_ups/index", type: :view do
  before(:each) do
    assign(:project_rate_build_ups, [
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
      ),
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
    ])
  end

  it "renders a list of project_rate_build_ups" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
  end
end
