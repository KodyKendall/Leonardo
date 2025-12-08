require 'rails_helper'

RSpec.describe "budget_categories/edit", type: :view do
  let(:budget_category) { create(:budget_category) }

  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:budget_category, budget_category)
  end

  it "renders the edit budget_category form" do
    render

    assert_select "form[action=?][method=?]", budget_category_path(budget_category), "post" do

      assert_select "input[name=?]", "budget_category[category_name]"

      assert_select "input[name=?]", "budget_category[cost_code]"

      assert_select "textarea[name=?]", "budget_category[description]"
    end
  end
end
