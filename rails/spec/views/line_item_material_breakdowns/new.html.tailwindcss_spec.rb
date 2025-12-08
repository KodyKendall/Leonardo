require 'rails_helper'

RSpec.describe "line_item_material_breakdowns/new", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:line_item_material_breakdown, LineItemMaterialBreakdown.new(
      tender_line_item: nil
    ))
  end

  it "renders new line_item_material_breakdown form" do
    render

    assert_select "form[action=?][method=?]", line_item_material_breakdowns_path, "post" do

      assert_select "input[name=?]", "line_item_material_breakdown[tender_line_item_id]"
    end
  end
end
