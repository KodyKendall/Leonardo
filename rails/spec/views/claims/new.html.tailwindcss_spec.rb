require 'rails_helper'

RSpec.describe "claims/new", type: :view do
  before(:each) do
    assign(:claim, Claim.new(
      claim_number: "MyString",
      project: nil,
      claim_status: "MyString",
      total_claimed: "9.99",
      total_paid: "9.99",
      amount_due: "9.99",
      submitted_by: nil,
      notes: "MyText"
    ))
  end

  it "renders new claim form" do
    render

    assert_select "form[action=?][method=?]", claims_path, "post" do

      assert_select "input[name=?]", "claim[claim_number]"

      assert_select "input[name=?]", "claim[project_id]"

      assert_select "input[name=?]", "claim[claim_status]"

      assert_select "input[name=?]", "claim[total_claimed]"

      assert_select "input[name=?]", "claim[total_paid]"

      assert_select "input[name=?]", "claim[amount_due]"

      assert_select "input[name=?]", "claim[submitted_by_id]"

      assert_select "textarea[name=?]", "claim[notes]"
    end
  end
end
