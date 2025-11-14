require 'rails_helper'

RSpec.describe "material_supplies/index", type: :view do
  before(:each) do
    assign(:material_supplies, [
      MaterialSupply.create!(
        name: "Name",
        waste_percentage: "9.99"
      ),
      MaterialSupply.create!(
        name: "Name",
        waste_percentage: "9.99"
      )
    ])
  end

  it "renders a list of material_supplies" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
  end
end
