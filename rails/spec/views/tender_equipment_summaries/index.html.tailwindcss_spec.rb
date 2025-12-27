require 'rails_helper'

RSpec.describe "tender_equipment_summaries/index", type: :view do
  before(:each) do
    assign(:tender_equipment_summaries, [
      TenderEquipmentSummary.create!(
        tender: nil,
        equipment_subtotal: "9.99",
        mobilization_fee: "9.99",
        total_equipment_cost: "9.99",
        rate_per_tonne_raw: "9.99",
        rate_per_tonne_rounded: "9.99"
      ),
      TenderEquipmentSummary.create!(
        tender: nil,
        equipment_subtotal: "9.99",
        mobilization_fee: "9.99",
        total_equipment_cost: "9.99",
        rate_per_tonne_raw: "9.99",
        rate_per_tonne_rounded: "9.99"
      )
    ])
  end

  it "renders a list of tender_equipment_summaries" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
  end
end
