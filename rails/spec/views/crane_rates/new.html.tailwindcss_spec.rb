require 'rails_helper'

RSpec.describe "crane_rates/new", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:crane_rate, CraneRate.new(
      size: "MyString",
      ownership_type: "MyString",
      dry_rate_per_day: "9.99",
      diesel_per_day: "9.99",
      is_active: false
    ))
  end

  it "renders new crane_rate form" do
    render

    assert_select "form[action=?][method=?]", crane_rates_path, "post" do

      assert_select "input[name=?]", "crane_rate[size]"

      assert_select "input[name=?]", "crane_rate[ownership_type]"

      assert_select "input[name=?]", "crane_rate[dry_rate_per_day]"

      assert_select "input[name=?]", "crane_rate[diesel_per_day]"

      assert_select "input[name=?]", "crane_rate[is_active]"
    end
  end
end
