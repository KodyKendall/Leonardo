require 'rails_helper'

RSpec.describe "budget_categories/show", type: :view do
  before(:each) do
    assign(:budget_category, BudgetCategory.create!(
      category_name: "Category Name",
      cost_code: "Cost Code",
      description: "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Category Name/)
    expect(rendered).to match(/Cost Code/)
    expect(rendered).to match(/MyText/)
  end
end
