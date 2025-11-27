require 'rails_helper'

RSpec.describe "line_item_rate_build_ups/index", type: :view do
  before(:each) do
    assign(:line_item_rate_build_ups, [
      LineItemRateBuildUp.create!(
        tender_line_item: nil,
        material_supply_rate: "9.99",
        fabrication_rate: "9.99",
        fabrication_included: false,
        overheads_rate: "9.99",
        overheads_included: false,
        shop_priming_rate: "9.99",
        shop_priming_included: false,
        onsite_painting_rate: "9.99",
        onsite_painting_included: false,
        delivery_rate: "9.99",
        delivery_included: false,
        bolts_rate: "9.99",
        bolts_included: false,
        erection_rate: "9.99",
        erection_included: false,
        crainage_rate: "9.99",
        crainage_included: false,
        cherry_picker_rate: "9.99",
        cherry_picker_included: false,
        galvanizing_rate: "9.99",
        galvanizing_included: false,
        subtotal: "9.99",
        margin_amount: "9.99",
        total_before_rounding: "9.99",
        rounded_rate: "9.99"
      ),
      LineItemRateBuildUp.create!(
        tender_line_item: nil,
        material_supply_rate: "9.99",
        fabrication_rate: "9.99",
        fabrication_included: false,
        overheads_rate: "9.99",
        overheads_included: false,
        shop_priming_rate: "9.99",
        shop_priming_included: false,
        onsite_painting_rate: "9.99",
        onsite_painting_included: false,
        delivery_rate: "9.99",
        delivery_included: false,
        bolts_rate: "9.99",
        bolts_included: false,
        erection_rate: "9.99",
        erection_included: false,
        crainage_rate: "9.99",
        crainage_included: false,
        cherry_picker_rate: "9.99",
        cherry_picker_included: false,
        galvanizing_rate: "9.99",
        galvanizing_included: false,
        subtotal: "9.99",
        margin_amount: "9.99",
        total_before_rounding: "9.99",
        rounded_rate: "9.99"
      )
    ])
  end

  it "renders a list of line_item_rate_build_ups" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
  end
end
