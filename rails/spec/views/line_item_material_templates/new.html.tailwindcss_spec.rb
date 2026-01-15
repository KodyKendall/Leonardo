require 'rails_helper'

RSpec.describe "line_item_material_templates/new", type: :view do
  before(:each) do
    assign(:line_item_material_template, LineItemMaterialTemplate.new(
      section_category_template: nil,
      material_supply: nil,
      proportion_percentage: "9.99",
      waste_percentage: "9.99",
      sort_order: 1
    ))
  end

  it "renders new line_item_material_template form" do
    render

    assert_select "form[action=?][method=?]", line_item_material_templates_path, "post" do

      assert_select "input[name=?]", "line_item_material_template[section_category_template_id]"

      assert_select "input[name=?]", "line_item_material_template[material_supply_id]"

      assert_select "input[name=?]", "line_item_material_template[proportion_percentage]"

      assert_select "input[name=?]", "line_item_material_template[waste_percentage]"

      assert_select "input[name=?]", "line_item_material_template[sort_order]"
    end
  end
end
