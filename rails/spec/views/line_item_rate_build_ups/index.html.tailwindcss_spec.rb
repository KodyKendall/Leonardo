require 'rails_helper'

RSpec.describe "line_item_rate_build_ups/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @line_item_rate_build_ups = [create(:line_item_rate_build_up), create(:line_item_rate_build_up)]
    assign(:line_item_rate_build_ups, @line_item_rate_build_ups)
  end

  it "renders a list of line_item_rate_build_ups" do
    render
  end
end
