require 'rails_helper'

RSpec.describe "on_site_mobile_crane_breakdowns/show", type: :view do
  before(:each) do
    assign(:on_site_mobile_crane_breakdown, OnSiteMobileCraneBreakdown.create!(
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
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/Ownership Type/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/Splicing Crane Size/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/Misc Crane Size/)
    expect(rendered).to match(/4/)
  end
end
