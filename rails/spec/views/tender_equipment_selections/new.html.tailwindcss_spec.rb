require 'rails_helper'

RSpec.describe "tender_equipment_selections/new", type: :view do
  before(:each) do
    assign(:tender_equipment_selection, TenderEquipmentSelection.new(
      tender: nil,
      equipment_type: nil,
      units_required: 1,
      period_months: 1,
      purpose: "MyString",
      monthly_cost_override: "9.99",
      calculated_monthly_cost: "9.99",
      total_cost: "9.99",
      sort_order: 1
    ))
  end

  it "renders new tender_equipment_selection form" do
    render

    assert_select "form[action=?][method=?]", tender_equipment_selections_path, "post" do

      assert_select "input[name=?]", "tender_equipment_selection[tender_id]"

      assert_select "input[name=?]", "tender_equipment_selection[equipment_type_id]"

      assert_select "input[name=?]", "tender_equipment_selection[units_required]"

      assert_select "input[name=?]", "tender_equipment_selection[period_months]"

      assert_select "input[name=?]", "tender_equipment_selection[purpose]"

      assert_select "input[name=?]", "tender_equipment_selection[monthly_cost_override]"

      assert_select "input[name=?]", "tender_equipment_selection[calculated_monthly_cost]"

      assert_select "input[name=?]", "tender_equipment_selection[total_cost]"

      assert_select "input[name=?]", "tender_equipment_selection[sort_order]"
    end
  end
end
