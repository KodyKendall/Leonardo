require 'rails_helper'

RSpec.describe "claims/show", type: :view do
  before(:each) do
    assign(:claim, Claim.create!(
      claim_number: "Claim Number",
      project: nil,
      claim_status: "Claim Status",
      total_claimed: "9.99",
      total_paid: "9.99",
      amount_due: "9.99",
      submitted_by: nil,
      notes: "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Claim Number/)
    expect(rendered).to match(//)
    expect(rendered).to match(/Claim Status/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(//)
    expect(rendered).to match(/MyText/)
  end
end
