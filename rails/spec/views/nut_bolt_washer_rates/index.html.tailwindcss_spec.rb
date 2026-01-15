require 'rails_helper'

RSpec.describe "nut_bolt_washer_rates/index", type: :view do
  before(:each) do
    assign(:nut_bolt_washer_rates, [
      NutBoltWasherRate.create!(
        name: "Name",
        waste_percentage: "9.99",
        material_cost: "9.99"
      ),
      NutBoltWasherRate.create!(
        name: "Name",
        waste_percentage: "9.99",
        material_cost: "9.99"
      )
    ])
  end

  it "renders a list of nut_bolt_washer_rates" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
  end
end
