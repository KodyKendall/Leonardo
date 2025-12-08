require 'rails_helper'

RSpec.describe "budget_categories/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @budget_categories = [create(:budget_category), create(:budget_category)]
    assign(:budget_categories, @budget_categories)
  end

  it "renders a list of budget_categories" do
    render
  end
end
