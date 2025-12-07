require 'rails_helper'

RSpec.describe "crane_rates/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @crane_rate = create(:crane_rate)
    assign(:crane_rate, @crane_rate)
  end

  it "renders attributes in <p>" do
    render
  end
end
