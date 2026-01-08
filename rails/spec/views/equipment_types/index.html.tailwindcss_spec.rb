require 'rails_helper'

RSpec.describe "equipment_types/index", type: :view do
  before(:each) do
    # Stub Pundit policy
    without_partial_double_verification do
      allow(view).to receive(:policy) do |record|
        double('policy', new?: true, edit?: true, destroy?: true)
      end
    end

    assign(:equipment_types, [
      EquipmentType.create!(
        category: "diesel_boom",
        model: "Model 1",
        working_height_m: 10,
        base_rate_monthly: 1000,
        damage_waiver_pct: 0.06,
        diesel_allowance_monthly: 500,
        is_active: true
      ),
      EquipmentType.create!(
        category: "electric_scissors",
        model: "Model 2",
        working_height_m: 8,
        base_rate_monthly: 800,
        damage_waiver_pct: 0.05,
        diesel_allowance_monthly: 0,
        is_active: false
      )
    ])
  end

  it "renders a list of equipment_types" do
    render
    cell_selector = 'tr>td'
    assert_select cell_selector, text: Regexp.new("Diesel Boom"), count: 1
    assert_select cell_selector, text: Regexp.new("Electric Scissors"), count: 1
    assert_select cell_selector, text: Regexp.new("Model 1"), count: 1
    assert_select cell_selector, text: Regexp.new("Model 2"), count: 1
    
    # Base rates
    assert_select cell_selector, text: Regexp.new("R1,000"), count: 1
    assert_select cell_selector, text: Regexp.new("R800"), count: 1

    # Monthly Rate incl. DW
    # (1000 * 1.06) + 500 = 1560
    assert_select cell_selector, text: Regexp.new("R1,560"), count: 1
    # (800 * 1.05) + 0 = 840
    assert_select cell_selector, text: Regexp.new("R840"), count: 1
  end
end
