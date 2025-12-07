require 'rails_helper'

RSpec.describe "line_item_rate_build_ups/edit", type: :view do
  let(:line_item_rate_build_up) { create(:line_item_rate_build_up) }

  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:line_item_rate_build_up, line_item_rate_build_up)
  end

  it "renders the edit line_item_rate_build_up form" do
    render

    assert_select "form[action=?][method=?]", line_item_rate_build_up_path(line_item_rate_build_up), "post" do

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
