require 'rails_helper'

RSpec.describe "line_item_materials/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:line_item_materials, [
      @line_item_material = create(:line_item_material),
      @line_item_material = create(:line_item_material)
    ])
  end

  it "renders a list of line_item_materials" do
    render
    expect(rendered).to match(/line_item_materials/)
  end
end
