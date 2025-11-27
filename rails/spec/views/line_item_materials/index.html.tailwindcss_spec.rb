require 'rails_helper'

RSpec.describe "line_item_materials/index", type: :view do
  before(:each) do
    assign(:line_item_materials, [
      LineItemMaterial.create!(
        tender_line_item: nil,
        material_supply: nil,
        proportion: "9.99"
      ),
      LineItemMaterial.create!(
        tender_line_item: nil,
        material_supply: nil,
        proportion: "9.99"
      )
    ])
  end

  it "renders a list of line_item_materials" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
  end
end
