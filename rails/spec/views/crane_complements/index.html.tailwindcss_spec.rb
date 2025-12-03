require 'rails_helper'

RSpec.describe "crane_complements/index", type: :view do
  before(:each) do
    assign(:crane_complements, [
      CraneComplement.create!(
        area_min_sqm: "9.99",
        area_max_sqm: "9.99",
        crane_recommendation: "Crane Recommendation",
        default_wet_rate_per_day: "9.99"
      ),
      CraneComplement.create!(
        area_min_sqm: "9.99",
        area_max_sqm: "9.99",
        crane_recommendation: "Crane Recommendation",
        default_wet_rate_per_day: "9.99"
      )
    ])
  end

  it "renders a list of crane_complements" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Crane Recommendation".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
  end
end
