require 'rails_helper'

RSpec.describe "budget_allowances/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @budget_allowance = create(:budget_allowance)
    assign(:budget_allowance, @budget_allowance)
  end

  it "renders attributes in <p>" do
    render
  end
end
