require 'rails_helper'

RSpec.describe "line_item_material_templates/edit", type: :view do
  let(:line_item_material_template) {
    LineItemMaterialTemplate.create!(
      section_category_template: nil,
      material_supply: nil,
      proportion_percentage: "9.99",
      waste_percentage: "9.99",
      sort_order: 1
    )
  }

  before(:each) do
    assign(:line_item_material_template, line_item_material_template)
  end

  it "renders the edit line_item_material_template form" do
    render

    assert_select "form[action=?][method=?]", line_item_material_template_path(line_item_material_template), "post" do

      assert_select "input[name=?]", "line_item_material_template[section_category_template_id]"

      assert_select "input[name=?]", "line_item_material_template[material_supply_id]"

      assert_select "input[name=?]", "line_item_material_template[proportion_percentage]"

      assert_select "input[name=?]", "line_item_material_template[waste_percentage]"

      assert_select "input[name=?]", "line_item_material_template[sort_order]"
    end
  end
end
