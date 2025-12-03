require 'rails_helper'

RSpec.describe "crane_rates/index", type: :view do
  before(:each) do
    assign(:crane_rates, [
      CraneRate.create!(
        size: "Size",
        ownership_type: "Ownership Type",
        dry_rate_per_day: "9.99",
        diesel_per_day: "9.99",
        is_active: false
      ),
      CraneRate.create!(
        size: "Size",
        ownership_type: "Ownership Type",
        dry_rate_per_day: "9.99",
        diesel_per_day: "9.99",
        is_active: false
      )
    ])
  end

  it "renders a list of crane_rates" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Size".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Ownership Type".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
  end
end
