require 'rails_helper'

RSpec.describe "material_supplies/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @material_supplies = [create(:material_supply), create(:material_supply)]
    assign(:material_supplies, @material_supplies)
  end

  it "renders a list of material_supplies" do
    render
  end
end
