require 'rails_helper'

RSpec.describe "material_supply_rates/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @material_supply_rates = [create(:material_supply_rate), create(:material_supply_rate)]
    assign(:material_supply_rates, @material_supply_rates)
  end

  it "renders a list of material_supply_rates" do
    render
  end
end
