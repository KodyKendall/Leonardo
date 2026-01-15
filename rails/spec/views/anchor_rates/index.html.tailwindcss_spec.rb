require 'rails_helper'

RSpec.describe "anchor_rates/index", type: :view do
  before(:each) do
    assign(:anchor_rates, [
      AnchorRate.create!(
        name: "Name",
        waste_percentage: "9.99",
        material_cost: "9.99"
      ),
      AnchorRate.create!(
        name: "Name",
        waste_percentage: "9.99",
        material_cost: "9.99"
      )
    ])
  end

  it "renders a list of anchor_rates" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
  end
end
