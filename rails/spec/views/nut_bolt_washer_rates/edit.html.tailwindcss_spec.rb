require 'rails_helper'

RSpec.describe "nut_bolt_washer_rates/edit", type: :view do
  let(:nut_bolt_washer_rate) {
    NutBoltWasherRate.create!(
      name: "MyString",
      waste_percentage: "9.99",
      material_cost: "9.99"
    )
  }

  before(:each) do
    assign(:nut_bolt_washer_rate, nut_bolt_washer_rate)
  end

  it "renders the edit nut_bolt_washer_rate form" do
    render

    assert_select "form[action=?][method=?]", nut_bolt_washer_rate_path(nut_bolt_washer_rate), "post" do

      assert_select "input[name=?]", "nut_bolt_washer_rate[name]"

      assert_select "input[name=?]", "nut_bolt_washer_rate[waste_percentage]"

      assert_select "input[name=?]", "nut_bolt_washer_rate[material_cost]"
    end
  end
end
