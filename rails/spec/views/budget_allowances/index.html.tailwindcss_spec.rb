require 'rails_helper'

RSpec.describe "budget_allowances/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @budget_allowances = [create(:budget_allowance), create(:budget_allowance)]
    assign(:budget_allowances, @budget_allowances)
  end

  it "renders a list of budget_allowances" do
    render
  end
end
