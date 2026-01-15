require 'rails_helper'

RSpec.describe "nut_bolt_washer_rates/new", type: :view do
  before(:each) do
    assign(:nut_bolt_washer_rate, NutBoltWasherRate.new(
      name: "MyString",
      waste_percentage: "9.99",
      material_cost: "9.99"
    ))
  end

  it "renders new nut_bolt_washer_rate form" do
    render

    assert_select "form[action=?][method=?]", nut_bolt_washer_rates_path, "post" do

      assert_select "input[name=?]", "nut_bolt_washer_rate[name]"

      assert_select "input[name=?]", "nut_bolt_washer_rate[waste_percentage]"

      assert_select "input[name=?]", "nut_bolt_washer_rate[material_cost]"
    end
  end
end
