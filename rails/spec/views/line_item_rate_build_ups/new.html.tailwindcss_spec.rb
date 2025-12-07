require 'rails_helper'

RSpec.describe "line_item_rate_build_ups/new", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:line_item_rate_build_up, LineItemRateBuildUp.new(
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
    ))
  end

  it "renders new line_item_rate_build_up form" do
    render

    assert_select "form[action=?][method=?]", line_item_rate_build_ups_path, "post" do

      assert_select "input[name=?]", "line_item_rate_build_up[tender_line_item_id]"

      assert_select "input[name=?]", "line_item_rate_build_up[material_supply_rate]"

      assert_select "input[name=?]", "line_item_rate_build_up[fabrication_rate]"

      assert_select "input[name=?]", "line_item_rate_build_up[fabrication_included]"

      assert_select "input[name=?]", "line_item_rate_build_up[overheads_rate]"

      assert_select "input[name=?]", "line_item_rate_build_up[overheads_included]"

      assert_select "input[name=?]", "line_item_rate_build_up[shop_priming_rate]"

      assert_select "input[name=?]", "line_item_rate_build_up[shop_priming_included]"

      assert_select "input[name=?]", "line_item_rate_build_up[onsite_painting_rate]"

      assert_select "input[name=?]", "line_item_rate_build_up[onsite_painting_included]"

      assert_select "input[name=?]", "line_item_rate_build_up[delivery_rate]"

      assert_select "input[name=?]", "line_item_rate_build_up[delivery_included]"

      assert_select "input[name=?]", "line_item_rate_build_up[bolts_rate]"

      assert_select "input[name=?]", "line_item_rate_build_up[bolts_included]"

      assert_select "input[name=?]", "line_item_rate_build_up[erection_rate]"

      assert_select "input[name=?]", "line_item_rate_build_up[erection_included]"

      assert_select "input[name=?]", "line_item_rate_build_up[crainage_rate]"

      assert_select "input[name=?]", "line_item_rate_build_up[crainage_included]"

      assert_select "input[name=?]", "line_item_rate_build_up[cherry_picker_rate]"

      assert_select "input[name=?]", "line_item_rate_build_up[cherry_picker_included]"

      assert_select "input[name=?]", "line_item_rate_build_up[galvanizing_rate]"

      assert_select "input[name=?]", "line_item_rate_build_up[galvanizing_included]"

      assert_select "input[name=?]", "line_item_rate_build_up[subtotal]"

      assert_select "input[name=?]", "line_item_rate_build_up[margin_amount]"

      assert_select "input[name=?]", "line_item_rate_build_up[total_before_rounding]"

      assert_select "input[name=?]", "line_item_rate_build_up[rounded_rate]"
    end
  end
end
