require 'rails_helper'

RSpec.describe "crane_complements/show", type: :view do
  before(:each) do
    assign(:crane_complement, CraneComplement.create!(
      area_min_sqm: "9.99",
      area_max_sqm: "9.99",
      crane_recommendation: "Crane Recommendation",
      default_wet_rate_per_day: "9.99"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/Crane Recommendation/)
    expect(rendered).to match(/9.99/)
  end
end
