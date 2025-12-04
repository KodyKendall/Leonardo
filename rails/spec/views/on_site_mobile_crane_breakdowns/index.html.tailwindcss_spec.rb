require 'rails_helper'

RSpec.describe "on_site_mobile_crane_breakdowns/index", type: :view do
  before(:each) do
    assign(:on_site_mobile_crane_breakdowns, [
      OnSiteMobileCraneBreakdown.create!(
        tender_id: "",
        total_roof_area_sqm: "9.99",
        erection_rate_sqm_per_day: "9.99",
        program_duration_days: 2,
        ownership_type: "Ownership Type",
        splicing_crane_required: false,
        splicing_crane_size: "Splicing Crane Size",
        splicing_crane_days: 3,
        misc_crane_required: false,
        misc_crane_size: "Misc Crane Size",
        misc_crane_days: 4
      ),
      OnSiteMobileCraneBreakdown.create!(
        tender_id: "",
        total_roof_area_sqm: "9.99",
        erection_rate_sqm_per_day: "9.99",
        program_duration_days: 2,
        ownership_type: "Ownership Type",
        splicing_crane_required: false,
        splicing_crane_size: "Splicing Crane Size",
        splicing_crane_days: 3,
        misc_crane_required: false,
        misc_crane_size: "Misc Crane Size",
        misc_crane_days: 4
      )
    ])
  end

  it "renders a list of on_site_mobile_crane_breakdowns" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Ownership Type".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Splicing Crane Size".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Misc Crane Size".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
  end
end
