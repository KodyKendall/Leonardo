require 'rails_helper'

RSpec.describe "line_item_material_breakdowns/show", type: :view do
  before(:each) do
    assign(:line_item_material_breakdown, LineItemMaterialBreakdown.create!(
      tender_line_item: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
  end
end
