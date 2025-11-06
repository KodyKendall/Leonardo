require 'rails_helper'

RSpec.describe "variation_orders/index", type: :view do
  before(:each) do
    assign(:variation_orders, [
      VariationOrder.create!(
        vo_number: "Vo Number",
        project: nil,
        vo_status: "Vo Status",
        vo_amount: "9.99",
        description: "MyText",
        created_by: nil,
        approved_by: nil,
        approver_notes: "MyText"
      ),
      VariationOrder.create!(
        vo_number: "Vo Number",
        project: nil,
        vo_status: "Vo Status",
        vo_amount: "9.99",
        description: "MyText",
        created_by: nil,
        approved_by: nil,
        approver_notes: "MyText"
      )
    ])
  end

  it "renders a list of variation_orders" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Vo Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Vo Status".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
  end
end
