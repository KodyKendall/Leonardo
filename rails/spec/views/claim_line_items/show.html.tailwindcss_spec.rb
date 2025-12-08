require 'rails_helper'

RSpec.describe "claim_line_items/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:claim_line_item, @claim_line_item = create(:claim_line_item))
  end

  it "renders attributes in <p>" do
    render
  end
end
