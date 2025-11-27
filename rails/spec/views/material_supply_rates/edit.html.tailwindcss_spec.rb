require 'rails_helper'

RSpec.describe "material_supply_rates/edit", type: :view do
  let(:material_supply_rate) {
    MaterialSupplyRate.create!(
      rate: "9.99",
      unit: "MyString",
      material_supply: nil,
      supplier: nil,
      monthly_material_supply_rate: nil
    )
  }

  before(:each) do
    assign(:material_supply_rate, material_supply_rate)
  end

  it "renders the edit material_supply_rate form" do
    render

    assert_select "form[action=?][method=?]", material_supply_rate_path(material_supply_rate), "post" do

      assert_select "input[name=?]", "material_supply_rate[rate]"

      assert_select "input[name=?]", "material_supply_rate[unit]"

      assert_select "input[name=?]", "material_supply_rate[material_supply_id]"

      assert_select "input[name=?]", "material_supply_rate[supplier_id]"

      assert_select "input[name=?]", "material_supply_rate[monthly_material_supply_rate_id]"
    end
  end
end
