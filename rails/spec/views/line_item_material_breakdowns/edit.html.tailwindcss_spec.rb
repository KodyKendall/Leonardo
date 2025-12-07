require 'rails_helper'

RSpec.describe "line_item_material_breakdowns/edit", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
  end
  let(:line_item_material_breakdown) {
    create(:line_item_material_breakdown
    )
  }

  before(:each) do
    assign(:line_item_material_breakdown, line_item_material_breakdown)
  end

  it "renders the edit line_item_material_breakdown form" do
    render

    assert_select "form[action=?][method=?]", line_item_material_breakdown_path(line_item_material_breakdown), "post" do

      assert_select "input[name=?]", "line_item_material_breakdown[tender_line_item_id]"
    end
  end
end
