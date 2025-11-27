require 'rails_helper'

RSpec.describe "line_item_material_breakdowns/index", type: :view do
  before(:each) do
    assign(:line_item_material_breakdowns, [
      LineItemMaterialBreakdown.create!(
        tender_line_item: nil
      ),
      LineItemMaterialBreakdown.create!(
        tender_line_item: nil
      )
    ])
  end

  it "renders a list of line_item_material_breakdowns" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
