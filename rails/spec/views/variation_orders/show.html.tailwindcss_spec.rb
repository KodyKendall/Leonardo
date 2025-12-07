require 'rails_helper'

RSpec.describe "variation_orders/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @variation_order = create(:variation_order)
    assign(:variation_order, @variation_order)
  end

  it "renders attributes in <p>" do
    render
  end
end
