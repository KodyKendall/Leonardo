require 'rails_helper'

RSpec.describe "material_supply_rates/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @material_supply_rate = create(:material_supply_rate)
    assign(:material_supply_rate, @material_supply_rate)
  end

  it "renders attributes in <p>" do
    render
  end
end
