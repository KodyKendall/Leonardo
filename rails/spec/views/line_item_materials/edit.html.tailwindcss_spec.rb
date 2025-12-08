require 'rails_helper'

RSpec.describe "line_item_materials/edit", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
  end
  let(:line_item_material) {
    @line_item_material = create(:line_item_material)
  }

  before(:each) do
    assign(:line_item_material, line_item_material)
  end

  it "renders the edit line_item_material form" do
    render

    assert_select "form[action=?][method=?]", line_item_material_path(line_item_material), "post" do
      assert_select "select[name=?]", "line_item_material[material_supply_id]"
      assert_select "input[name=?]", "line_item_material[proportion]"
    end
  end
end
