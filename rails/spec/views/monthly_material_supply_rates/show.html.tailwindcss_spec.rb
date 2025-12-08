require 'rails_helper'

RSpec.describe "monthly_material_supply_rates/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @suppliers = [create(:supplier), create(:supplier)]
    @material_supplies = [create(:material_supply), create(:material_supply)]
    assign(:suppliers, @suppliers)
    assign(:material_supplies, @material_supplies)
    assign(:existing_rates, {})
    assign(:monthly_material_supply_rate, create(:monthly_material_supply_rate))
  end

  it "renders attributes in <p>" do
    render
  end
end
