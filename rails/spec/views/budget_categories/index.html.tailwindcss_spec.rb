require 'rails_helper'

RSpec.describe "budget_categories/index", type: :view do
  before(:each) do
    assign(:budget_categories, [
      BudgetCategory.create!(
        category_name: "Category Name",
        cost_code: "Cost Code",
        description: "MyText"
      ),
      BudgetCategory.create!(
        category_name: "Category Name",
        cost_code: "Cost Code",
        description: "MyText"
      )
    ])
  end

  it "renders a list of budget_categories" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Category Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Cost Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
  end
end
