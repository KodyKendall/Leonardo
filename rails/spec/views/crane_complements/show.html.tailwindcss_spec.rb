require 'rails_helper'

RSpec.describe "crane_complements/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @crane_complement = create(:crane_complement)
    assign(:crane_complement, @crane_complement)
  end

  it "renders attributes in <p>" do
    render
  end
end
