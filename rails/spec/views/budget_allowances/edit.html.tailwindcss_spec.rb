require 'rails_helper'

RSpec.describe "budget_allowances/edit", type: :view do
  let(:budget_allowance) {
    BudgetAllowance.create!(
      project: nil,
      budget_category: nil,
      budgeted_amount: "9.99",
      actual_spend: "9.99",
      variance: "9.99"
    )
  }

  before(:each) do
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
