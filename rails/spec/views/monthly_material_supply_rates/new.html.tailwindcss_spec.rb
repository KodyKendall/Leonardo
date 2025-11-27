require 'rails_helper'

RSpec.describe "monthly_material_supply_rates/new", type: :view do
  before(:each) do
    assign(:monthly_material_supply_rate, MonthlyMaterialSupplyRate.new())
  end

  it "renders new monthly_material_supply_rate form" do
    render

    assert_select "form[action=?][method=?]", monthly_material_supply_rates_path, "post" do
    end
  end
end
