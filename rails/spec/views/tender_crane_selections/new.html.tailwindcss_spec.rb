require 'rails_helper'

RSpec.describe "tender_crane_selections/new", type: :view do
  before(:each) do
    assign(:tender_crane_selection, TenderCraneSelection.new(
      tender: nil,
      crane_rate: nil,
      purpose: "MyString",
      quantity: 1,
      duration_days: 1,
      wet_rate_per_day: "9.99",
      total_cost: "9.99",
      sort_order: 1
    ))
  end

  it "renders new tender_crane_selection form" do
    render

    assert_select "form[action=?][method=?]", tender_crane_selections_path, "post" do

      assert_select "input[name=?]", "tender_crane_selection[tender_id]"

      assert_select "input[name=?]", "tender_crane_selection[crane_rate_id]"

      assert_select "input[name=?]", "tender_crane_selection[purpose]"

      assert_select "input[name=?]", "tender_crane_selection[quantity]"

      assert_select "input[name=?]", "tender_crane_selection[duration_days]"

      assert_select "input[name=?]", "tender_crane_selection[wet_rate_per_day]"

      assert_select "input[name=?]", "tender_crane_selection[total_cost]"

      assert_select "input[name=?]", "tender_crane_selection[sort_order]"
    end
  end
end
