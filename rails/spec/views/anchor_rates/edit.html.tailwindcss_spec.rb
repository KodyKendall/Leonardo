require 'rails_helper'

RSpec.describe "anchor_rates/edit", type: :view do
  let(:anchor_rate) {
    AnchorRate.create!(
      name: "MyString",
      waste_percentage: "9.99",
      material_cost: "9.99"
    )
  }

  before(:each) do
    assign(:anchor_rate, anchor_rate)
  end

  it "renders the edit anchor_rate form" do
    render

    assert_select "form[action=?][method=?]", anchor_rate_path(anchor_rate), "post" do

      assert_select "input[name=?]", "anchor_rate[name]"

      assert_select "input[name=?]", "anchor_rate[waste_percentage]"

      assert_select "input[name=?]", "anchor_rate[material_cost]"
    end
  end
end
