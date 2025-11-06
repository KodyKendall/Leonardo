require 'rails_helper'

RSpec.describe "claim_line_items/show", type: :view do
  before(:each) do
    assign(:claim_line_item, ClaimLineItem.create!(
      claim: nil,
      line_item_description: "Line Item Description",
      tender_rate: "9.99",
      claimed_quantity: "9.99",
      claimed_amount: "9.99",
      cumulative_quantity: "9.99",
      is_new_item: false,
      price_escalation: "9.99"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Line Item Description/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/9.99/)
  end
end
