require 'rails_helper'

RSpec.describe "anchor_rates/show", type: :view do
  before(:each) do
    assign(:anchor_rate, AnchorRate.create!(
      name: "Name",
      waste_percentage: "9.99",
      material_cost: "9.99"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
  end
end
