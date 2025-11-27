require 'rails_helper'

RSpec.describe "material_supply_rates/show", type: :view do
  before(:each) do
    assign(:material_supply_rate, MaterialSupplyRate.create!(
      rate: "9.99",
      unit: "Unit",
      material_supply: nil,
      supplier: nil,
      monthly_material_supply_rate: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/Unit/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
