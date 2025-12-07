require 'rails_helper'

RSpec.describe "crane_complements/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @crane_complements = [create(:crane_complement), create(:crane_complement)]
    assign(:crane_complements, @crane_complements)
  end

  it "renders a list of crane_complements" do
    render
  end
end
