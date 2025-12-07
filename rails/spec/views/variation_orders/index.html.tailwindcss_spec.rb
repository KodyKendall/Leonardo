require 'rails_helper'

RSpec.describe "variation_orders/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @variation_orders = [create(:variation_order), create(:variation_order)]
    assign(:variation_orders, @variation_orders)
  end

  it "renders a list of variation_orders" do
    render
  end
end
