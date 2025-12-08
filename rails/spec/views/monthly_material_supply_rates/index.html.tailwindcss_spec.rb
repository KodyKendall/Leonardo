require 'rails_helper'

RSpec.describe "monthly_material_supply_rates/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:monthly_material_supply_rates, [
      create(:monthly_material_supply_rate),
      create(:monthly_material_supply_rate)
    ])
  end

  it "renders a list of monthly_material_supply_rates" do
    render
    cell_selector = 'div>p'
  end
end
