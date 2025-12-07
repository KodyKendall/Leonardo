require 'rails_helper'

RSpec.describe "claim_line_items/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:claim_line_items, [
      @claim_line_item = create(:claim_line_item),
      @claim_line_item = create(:claim_line_item)
    ])
  end

  it "renders a list of claim_line_items" do
    render
    expect(rendered).to match(/Claim line items/)
  end
end
