require 'rails_helper'

RSpec.describe "line_item_material_templates/index", type: :view do
  before(:each) do
    assign(:line_item_material_templates, [
      LineItemMaterialTemplate.create!(
        section_category_template: nil,
        material_supply: nil,
        proportion_percentage: "9.99",
        waste_percentage: "9.99",
        sort_order: 2
      ),
      LineItemMaterialTemplate.create!(
        section_category_template: nil,
        material_supply: nil,
        proportion_percentage: "9.99",
        waste_percentage: "9.99",
        sort_order: 2
      )
    ])
  end

  it "renders a list of line_item_material_templates" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
  end
end
