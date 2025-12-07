require 'rails_helper'

RSpec.describe "line_item_materials/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @line_item_material = create(:line_item_material)
    assign(:line_item_material, @line_item_material)
  end

  it "renders attributes in <p>" do
    render
  end
end
