require 'rails_helper'

RSpec.describe "equipment_types/index", type: :view do
  before(:each) do
    assign(:equipment_types, [
      EquipmentType.create!(
        category: "Category",
        model: "Model",
        working_height_m: "9.99",
        base_rate_monthly: "9.99",
        damage_waiver_pct: "9.99",
        diesel_allowance_monthly: "9.99",
        is_active: false
      ),
      EquipmentType.create!(
        category: "Category",
        model: "Model",
        working_height_m: "9.99",
        base_rate_monthly: "9.99",
        damage_waiver_pct: "9.99",
        diesel_allowance_monthly: "9.99",
        is_active: false
      )
    ])
  end

  it "renders a list of equipment_types" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Category".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Model".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
  end
end
