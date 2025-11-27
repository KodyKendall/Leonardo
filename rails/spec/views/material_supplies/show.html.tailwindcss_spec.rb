require 'rails_helper'

RSpec.describe "material_supplies/show", type: :view do
  before(:each) do
    assign(:material_supply, MaterialSupply.create!(
      name: "Name",
      waste_percentage: "9.99"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/9.99/)
  end
end
