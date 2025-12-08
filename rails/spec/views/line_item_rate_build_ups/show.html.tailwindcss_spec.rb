require 'rails_helper'

RSpec.describe "line_item_rate_build_ups/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @line_item_rate_build_up = create(:line_item_rate_build_up)
    assign(:line_item_rate_build_up, @line_item_rate_build_up)
  end

  it "renders attributes in <p>" do
    render
  end
end
