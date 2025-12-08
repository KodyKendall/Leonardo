require 'rails_helper'

RSpec.describe "material_supplies/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @material_supply = create(:material_supply)
    assign(:material_supply, @material_supply)
  end

  it "renders attributes in <p>" do
    render
  end
end
