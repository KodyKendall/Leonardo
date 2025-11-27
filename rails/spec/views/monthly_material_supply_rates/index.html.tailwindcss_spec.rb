require 'rails_helper'

RSpec.describe "monthly_material_supply_rates/index", type: :view do
  before(:each) do
    assign(:monthly_material_supply_rates, [
      MonthlyMaterialSupplyRate.create!(),
      MonthlyMaterialSupplyRate.create!()
    ])
  end

  it "renders a list of monthly_material_supply_rates" do
    render
    cell_selector = 'div>p'
  end
end
