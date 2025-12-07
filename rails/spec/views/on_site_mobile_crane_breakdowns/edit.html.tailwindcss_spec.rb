require 'rails_helper'

RSpec.describe "on_site_mobile_crane_breakdowns/edit", type: :view do
  let(:on_site_mobile_crane_breakdown) { create(:on_site_mobile_crane_breakdown) }

  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:on_site_mobile_crane_breakdown, on_site_mobile_crane_breakdown)
  end

  it "renders the edit on_site_mobile_crane_breakdown form" do
    render

    assert_select "form[action=?][method=?]", on_site_mobile_crane_breakdown_path(on_site_mobile_crane_breakdown), "post" do

      assert_select "input[name=?]", "on_site_mobile_crane_breakdown[tender_id]"

      assert_select "input[name=?]", "on_site_mobile_crane_breakdown[total_roof_area_sqm]"

      assert_select "input[name=?]", "on_site_mobile_crane_breakdown[erection_rate_sqm_per_day]"

      assert_select "input[name=?]", "on_site_mobile_crane_breakdown[program_duration_days]"

      assert_select "input[name=?]", "on_site_mobile_crane_breakdown[ownership_type]"

      assert_select "input[name=?]", "on_site_mobile_crane_breakdown[splicing_crane_required]"

      assert_select "input[name=?]", "on_site_mobile_crane_breakdown[splicing_crane_size]"

      assert_select "input[name=?]", "on_site_mobile_crane_breakdown[splicing_crane_days]"

      assert_select "input[name=?]", "on_site_mobile_crane_breakdown[misc_crane_required]"

      assert_select "input[name=?]", "on_site_mobile_crane_breakdown[misc_crane_size]"

      assert_select "input[name=?]", "on_site_mobile_crane_breakdown[misc_crane_days]"
    end
  end
end
