require 'rails_helper'

RSpec.describe "equipment_types/new", type: :view do
  before(:each) do
    assign(:equipment_type, EquipmentType.new(
      category: "MyString",
      model: "MyString",
      working_height_m: "9.99",
      base_rate_monthly: "9.99",
      damage_waiver_pct: "9.99",
      diesel_allowance_monthly: "9.99",
      is_active: false
    ))
  end

  it "renders new equipment_type form" do
    render

    assert_select "form[action=?][method=?]", equipment_types_path, "post" do

      assert_select "input[name=?]", "equipment_type[category]"

      assert_select "input[name=?]", "equipment_type[model]"

      assert_select "input[name=?]", "equipment_type[working_height_m]"

      assert_select "input[name=?]", "equipment_type[base_rate_monthly]"

      assert_select "input[name=?]", "equipment_type[damage_waiver_pct]"

      assert_select "input[name=?]", "equipment_type[diesel_allowance_monthly]"

      assert_select "input[name=?]", "equipment_type[is_active]"
    end
  end
end
