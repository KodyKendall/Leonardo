require 'rails_helper'

RSpec.describe "project_rate_build_ups/show", type: :view do
  before(:each) do
    assign(:project_rate_build_up, ProjectRateBuildUp.create!(
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
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
  end
end
