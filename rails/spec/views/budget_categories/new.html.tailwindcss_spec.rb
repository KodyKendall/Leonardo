require 'rails_helper'

RSpec.describe "budget_categories/new", type: :view do
  before(:each) do
    assign(:budget_category, BudgetCategory.new(
      category_name: "MyString",
      cost_code: "MyString",
      description: "MyText"
    ))
  end

  it "renders new budget_category form" do
    render

    assert_select "form[action=?][method=?]", budget_categories_path, "post" do

      assert_select "input[name=?]", "budget_category[category_name]"

      assert_select "input[name=?]", "budget_category[cost_code]"

      assert_select "textarea[name=?]", "budget_category[description]"
    end
  end
end
