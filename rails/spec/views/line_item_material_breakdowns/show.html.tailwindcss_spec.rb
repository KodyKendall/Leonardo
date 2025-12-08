require 'rails_helper'

RSpec.describe "line_item_material_breakdowns/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:line_item_material_breakdown, create(:line_item_material_breakdown))
  end

  it "renders attributes in <p>" do
    render
  end
end
