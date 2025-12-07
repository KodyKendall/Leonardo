require 'rails_helper'

RSpec.describe "material_supplies/new", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:material_supply, MaterialSupply.new(
      name: "MyString",
      waste_percentage: "9.99"
    ))
  end

  it "renders new material_supply form" do
    render

    assert_select "form[action=?][method=?]", material_supplies_path, "post" do

      assert_select "input[name=?]", "material_supply[name]"

      assert_select "input[name=?]", "material_supply[waste_percentage]"
    end
  end
end
