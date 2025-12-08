require 'rails_helper'

RSpec.describe "line_item_material_breakdowns/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:line_item_material_breakdowns, [
      create(:line_item_material_breakdown
      ),
      create(:line_item_material_breakdown
      )
    ])
  end

  it "renders a list of line_item_material_breakdowns" do
    render
    expect(rendered).to match(/Material Breakdowns/)
  end
end
