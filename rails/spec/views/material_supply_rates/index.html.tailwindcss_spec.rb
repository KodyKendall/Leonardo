require 'rails_helper'

RSpec.describe "material_supply_rates/index", type: :view do
  before(:each) do
    assign(:material_supply_rates, [
      MaterialSupplyRate.create!(
        rate: "9.99",
        unit: "Unit",
        material_supply: nil,
        supplier: nil,
        monthly_material_supply_rate: nil
      ),
      MaterialSupplyRate.create!(
        rate: "9.99",
        unit: "Unit",
        material_supply: nil,
        supplier: nil,
        monthly_material_supply_rate: nil
      )
    ])
  end

  it "renders a list of material_supply_rates" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Unit".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
