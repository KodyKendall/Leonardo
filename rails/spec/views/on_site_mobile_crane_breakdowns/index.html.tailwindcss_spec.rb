require 'rails_helper'

RSpec.describe "on_site_mobile_crane_breakdowns/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @on_site_mobile_crane_breakdowns = [create(:on_site_mobile_crane_breakdown), create(:on_site_mobile_crane_breakdown)]
    assign(:on_site_mobile_crane_breakdowns, @on_site_mobile_crane_breakdowns)
  end

  it "renders a list of on_site_mobile_crane_breakdowns" do
    render
  end
end
