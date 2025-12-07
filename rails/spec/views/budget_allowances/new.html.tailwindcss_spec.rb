require 'rails_helper'

RSpec.describe "budget_allowances/new", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:budget_allowance, BudgetAllowance.new(
      project: nil,
      budget_category: nil,
      budgeted_amount: "9.99",
      actual_spend: "9.99",
      variance: "9.99"
    ))
  end

  it "renders new budget_allowance form" do
    render

    assert_select "form[action=?][method=?]", budget_allowances_path, "post" do

      assert_select "input[name=?]", "budget_allowance[project_id]"

      assert_select "input[name=?]", "budget_allowance[budget_category_id]"

      assert_select "input[name=?]", "budget_allowance[budgeted_amount]"

      assert_select "input[name=?]", "budget_allowance[actual_spend]"

      assert_select "input[name=?]", "budget_allowance[variance]"
    end
  end
end
