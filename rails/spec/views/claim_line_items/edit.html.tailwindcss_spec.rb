require 'rails_helper'

RSpec.describe "claim_line_items/edit", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
  end
  let(:claim_line_item) {
    @claim_line_item = create(:claim_line_item)
  }

  before(:each) do
    assign(:claim_line_item, claim_line_item)
  end

  it "renders the edit claim_line_item form" do
    render

    assert_select "form[action=?][method=?]", claim_line_item_path(claim_line_item), "post" do

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
