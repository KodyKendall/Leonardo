require 'rails_helper'

RSpec.describe "crane_rates/show", type: :view do
  before(:each) do
    assign(:crane_rate, CraneRate.create!(
      size: "Size",
      ownership_type: "Ownership Type",
      dry_rate_per_day: "9.99",
      diesel_per_day: "9.99",
      is_active: false
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Size/)
    expect(rendered).to match(/Ownership Type/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/false/)
  end
end
