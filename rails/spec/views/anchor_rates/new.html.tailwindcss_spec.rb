require 'rails_helper'

RSpec.describe "anchor_rates/new", type: :view do
  before(:each) do
    assign(:anchor_rate, AnchorRate.new(
      name: "MyString",
      waste_percentage: "9.99",
      material_cost: "9.99"
    ))
  end

  it "renders new anchor_rate form" do
    render

    assert_select "form[action=?][method=?]", anchor_rates_path, "post" do

      assert_select "input[name=?]", "anchor_rate[name]"

      assert_select "input[name=?]", "anchor_rate[waste_percentage]"

      assert_select "input[name=?]", "anchor_rate[material_cost]"
    end
  end
end
