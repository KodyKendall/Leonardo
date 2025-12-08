require 'rails_helper'

RSpec.describe "budget_categories/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @budget_category = create(:budget_category)
    assign(:budget_category, @budget_category)
  end

  it "renders attributes in <p>" do
    render
  end
end
