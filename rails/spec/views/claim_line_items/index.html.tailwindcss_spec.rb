require 'rails_helper'

RSpec.describe "claim_line_items/index", type: :view do
  before(:each) do
    assign(:claim_line_items, [
      ClaimLineItem.create!(
        claim: nil,
        line_item_description: "Line Item Description",
        tender_rate: "9.99",
        claimed_quantity: "9.99",
        claimed_amount: "9.99",
        cumulative_quantity: "9.99",
        is_new_item: false,
        price_escalation: "9.99"
      ),
      ClaimLineItem.create!(
        claim: nil,
        line_item_description: "Line Item Description",
        tender_rate: "9.99",
        claimed_quantity: "9.99",
        claimed_amount: "9.99",
        cumulative_quantity: "9.99",
        is_new_item: false,
        price_escalation: "9.99"
      )
    ])
  end

  it "renders a list of claim_line_items" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Line Item Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
  end
end
