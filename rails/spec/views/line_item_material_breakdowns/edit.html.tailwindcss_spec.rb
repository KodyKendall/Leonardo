require 'rails_helper'

RSpec.describe "line_item_material_breakdowns/edit", type: :view do
  let(:line_item_material_breakdown) {
    LineItemMaterialBreakdown.create!(
      tender_line_item: nil
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
