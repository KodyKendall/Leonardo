require 'rails_helper'

RSpec.describe "material_supplies/edit", type: :view do
  let(:material_supply) { create(:material_supply) }

  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:material_supply, material_supply)
  end

  it "renders the edit material_supply form" do
    render

    assert_select "form[action=?][method=?]", material_supply_path(material_supply), "post" do

      assert_select "input[name=?]", "material_supply[name]"

      assert_select "input[name=?]", "material_supply[waste_percentage]"
    end
  end
end
