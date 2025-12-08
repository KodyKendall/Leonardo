require 'rails_helper'

RSpec.describe "on_site_mobile_crane_breakdowns/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @on_site_mobile_crane_breakdown = create(:on_site_mobile_crane_breakdown)
    assign(:on_site_mobile_crane_breakdown, @on_site_mobile_crane_breakdown)
  end

  it "renders attributes in <p>" do
    render
  end
end
