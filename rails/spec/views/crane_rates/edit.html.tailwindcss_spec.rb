require 'rails_helper'

RSpec.describe "crane_rates/edit", type: :view do
  let(:crane_rate) { create(:crane_rate) }

  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:crane_rate, crane_rate)
  end

  it "renders the edit crane_rate form" do
    render

    assert_select "form[action=?][method=?]", crane_rate_path(crane_rate), "post" do

      assert_select "input[name=?]", "crane_rate[size]"

      assert_select "input[name=?]", "crane_rate[ownership_type]"

      assert_select "input[name=?]", "crane_rate[dry_rate_per_day]"

      assert_select "input[name=?]", "crane_rate[diesel_per_day]"

      assert_select "input[name=?]", "crane_rate[is_active]"
    end
  end
end
