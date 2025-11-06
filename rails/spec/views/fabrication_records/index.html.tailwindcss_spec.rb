require 'rails_helper'

RSpec.describe "fabrication_records/index", type: :view do
  before(:each) do
    assign(:fabrication_records, [
      FabricationRecord.create!(
        project: nil,
        tonnes_fabricated: "9.99",
        allowed_rate: "9.99",
        allowed_amount: "9.99",
        actual_spend: "9.99"
      ),
      FabricationRecord.create!(
        project: nil,
        tonnes_fabricated: "9.99",
        allowed_rate: "9.99",
        allowed_amount: "9.99",
        actual_spend: "9.99"
      )
    ])
  end

  it "renders a list of fabrication_records" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
  end
end
