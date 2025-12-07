require 'rails_helper'

RSpec.describe "line_item_materials/new", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:line_item_material, LineItemMaterial.new(
      tender_line_item: nil,
      material_supply: nil,
      proportion: "9.99"
    ))
  end

  it "renders new line_item_material form" do
    render

    assert_select "form[action=?][method=?]", line_item_materials_path, "post" do
      assert_select "select[name=?]", "line_item_material[material_supply_id]"
      assert_select "input[name=?]", "line_item_material[proportion]"
    end
  end
end
