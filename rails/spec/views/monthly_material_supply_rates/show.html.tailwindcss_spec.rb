require 'rails_helper'

RSpec.describe "monthly_material_supply_rates/show", type: :view do
  before(:each) do
    assign(:monthly_material_supply_rate, MonthlyMaterialSupplyRate.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
