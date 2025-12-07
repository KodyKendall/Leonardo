require 'rails_helper'

RSpec.describe "crane_complements/edit", type: :view do
  let(:crane_complement) { create(:crane_complement) }

  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:crane_complement, crane_complement)
  end

  it "renders the edit crane_complement form" do
    render

    assert_select "form[action=?][method=?]", crane_complement_path(crane_complement), "post" do

      assert_select "input[name=?]", "crane_complement[area_min_sqm]"

      assert_select "input[name=?]", "crane_complement[area_max_sqm]"

      assert_select "input[name=?]", "crane_complement[crane_recommendation]"

      assert_select "input[name=?]", "crane_complement[default_wet_rate_per_day]"
    end
  end
end
