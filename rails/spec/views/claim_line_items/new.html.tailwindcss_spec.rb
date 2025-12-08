require 'rails_helper'

RSpec.describe "claim_line_items/new", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:claim_line_item, ClaimLineItem.new(
      claim: nil,
      line_item_description: "MyString",
      tender_rate: "9.99",
      claimed_quantity: "9.99",
      claimed_amount: "9.99",
      cumulative_quantity: "9.99",
      is_new_item: false,
      price_escalation: "9.99"
    ))
  end

  it "renders new claim_line_item form" do
    render

    assert_select "form[action=?][method=?]", claim_line_items_path, "post" do

      assert_select "input[name=?]", "claim_line_item[claim_id]"

      assert_select "input[name=?]", "claim_line_item[line_item_description]"

      assert_select "input[name=?]", "claim_line_item[tender_rate]"

      assert_select "input[name=?]", "claim_line_item[claimed_quantity]"

      assert_select "input[name=?]", "claim_line_item[claimed_amount]"

      assert_select "input[name=?]", "claim_line_item[cumulative_quantity]"

      assert_select "input[name=?]", "claim_line_item[is_new_item]"

      assert_select "input[name=?]", "claim_line_item[price_escalation]"
    end
  end
end
