require 'rails_helper'

RSpec.describe "budget_allowances/index", type: :view do
  before(:each) do
    assign(:budget_allowances, [
      BudgetAllowance.create!(
        project: nil,
        budget_category: nil,
        budgeted_amount: "9.99",
        actual_spend: "9.99",
        variance: "9.99"
      ),
      BudgetAllowance.create!(
        project: nil,
        budget_category: nil,
        budgeted_amount: "9.99",
        actual_spend: "9.99",
        variance: "9.99"
      )
    ])
  end

  it "renders a list of budget_allowances" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
  end
end
