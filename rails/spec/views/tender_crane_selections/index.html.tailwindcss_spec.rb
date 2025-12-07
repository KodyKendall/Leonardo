require 'rails_helper'

RSpec.describe "tender_crane_selections/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:tender_crane_selections, [
      @tender_crane_selection = create(:tender_crane_selection),
      @tender_crane_selection = create(:tender_crane_selection)
    ])
  end

  xit "renders a list of tender_crane_selections" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Purpose".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
  end
end
