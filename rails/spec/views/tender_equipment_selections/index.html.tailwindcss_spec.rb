require 'rails_helper'

RSpec.describe "tender_equipment_selections/index", type: :view do
  before(:each) do
    assign(:tender_equipment_selections, [
      TenderEquipmentSelection.create!(
        tender: nil,
        equipment_type: nil,
        units_required: 2,
        period_months: 3,
        purpose: "Purpose",
        monthly_cost_override: "9.99",
        calculated_monthly_cost: "9.99",
        total_cost: "9.99",
        sort_order: 4
      ),
      TenderEquipmentSelection.create!(
        tender: nil,
        equipment_type: nil,
        units_required: 2,
        period_months: 3,
        purpose: "Purpose",
        monthly_cost_override: "9.99",
        calculated_monthly_cost: "9.99",
        total_cost: "9.99",
        sort_order: 4
      )
    ])
  end

  it "renders a list of tender_equipment_selections" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Purpose".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
  end
end
