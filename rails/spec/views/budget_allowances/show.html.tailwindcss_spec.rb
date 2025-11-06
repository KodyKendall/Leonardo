require 'rails_helper'

RSpec.describe "budget_allowances/show", type: :view do
  before(:each) do
    assign(:budget_allowance, BudgetAllowance.create!(
      project: nil,
      budget_category: nil,
      budgeted_amount: "9.99",
      actual_spend: "9.99",
      variance: "9.99"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
  end
end
