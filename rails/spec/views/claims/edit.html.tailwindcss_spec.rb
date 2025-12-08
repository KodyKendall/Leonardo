require 'rails_helper'

RSpec.describe "claims/edit", type: :view do
  let(:claim) { create(:claim) }

  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:claim, claim)
  end

  it "renders the edit claim form" do
    render

    assert_select "form[action=?][method=?]", claim_path(claim), "post" do

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
