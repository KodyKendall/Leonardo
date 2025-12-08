require 'rails_helper'

RSpec.describe "tender_crane_selections/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:tender_crane_selection, @tender_crane_selection = create(:tender_crane_selection))
  end

  xit "renders attributes in <p>" do
    render
  end
end
