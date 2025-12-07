require 'rails_helper'

RSpec.describe "crane_rates/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @crane_rates = [create(:crane_rate), create(:crane_rate)]
    assign(:crane_rates, @crane_rates)
  end

  it "renders a list of crane_rates" do
    render
  end
end
