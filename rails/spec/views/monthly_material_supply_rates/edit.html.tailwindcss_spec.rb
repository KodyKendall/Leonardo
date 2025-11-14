require 'rails_helper'

RSpec.describe "monthly_material_supply_rates/edit", type: :view do
  let(:monthly_material_supply_rate) {
    MonthlyMaterialSupplyRate.create!()
  }

  before(:each) do
    assign(:monthly_material_supply_rate, monthly_material_supply_rate)
  end

  it "renders the edit monthly_material_supply_rate form" do
    render

    assert_select "form[action=?][method=?]", monthly_material_supply_rate_path(monthly_material_supply_rate), "post" do
    end
  end
end
