require 'rails_helper'

RSpec.describe "claims/index", type: :view do
  before(:each) do
    assign(:claims, [
      Claim.create!(
        claim_number: "Claim Number",
        project: nil,
        claim_status: "Claim Status",
        total_claimed: "9.99",
        total_paid: "9.99",
        amount_due: "9.99",
        submitted_by: nil,
        notes: "MyText"
      ),
      Claim.create!(
        claim_number: "Claim Number",
        project: nil,
        claim_status: "Claim Status",
        total_claimed: "9.99",
        total_paid: "9.99",
        amount_due: "9.99",
        submitted_by: nil,
        notes: "MyText"
      )
    ])
  end

  it "renders a list of claims" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Claim Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Claim Status".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
  end
end
