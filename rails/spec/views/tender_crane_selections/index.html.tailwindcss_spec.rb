require 'rails_helper'

RSpec.describe "tender_crane_selections/index", type: :view do
  before(:each) do
    assign(:tender_crane_selections, [
      TenderCraneSelection.create!(
        tender: nil,
        crane_rate: nil,
        purpose: "Purpose",
        quantity: 2,
        duration_days: 3,
        wet_rate_per_day: "9.99",
        total_cost: "9.99",
        sort_order: 4
      ),
      TenderCraneSelection.create!(
        tender: nil,
        crane_rate: nil,
        purpose: "Purpose",
        quantity: 2,
        duration_days: 3,
        wet_rate_per_day: "9.99",
        total_cost: "9.99",
        sort_order: 4
      )
    ])
  end

  it "renders a list of tender_crane_selections" do
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
