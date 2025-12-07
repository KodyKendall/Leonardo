require 'rails_helper'

RSpec.describe "budget_allowances/edit", type: :view do
  let(:budget_allowance) { create(:budget_allowance) }

  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:budget_allowance, budget_allowance)
  end

  it "renders the edit budget_allowance form" do
    render

    assert_select "form[action=?][method=?]", budget_allowance_path(budget_allowance), "post" do

      assert_select "input[name=?]", "budget_allowance[project_id]"

      assert_select "input[name=?]", "budget_allowance[budget_category_id]"

      assert_select "input[name=?]", "budget_allowance[budgeted_amount]"

      assert_select "input[name=?]", "budget_allowance[actual_spend]"

      assert_select "input[name=?]", "budget_allowance[variance]"
    end
  end
end
