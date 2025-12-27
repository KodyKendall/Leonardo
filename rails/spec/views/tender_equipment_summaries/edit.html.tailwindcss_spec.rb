require 'rails_helper'

RSpec.describe "tender_equipment_summaries/edit", type: :view do
  let(:tender_equipment_summary) {
    TenderEquipmentSummary.create!(
      tender: nil,
      equipment_subtotal: "9.99",
      mobilization_fee: "9.99",
      total_equipment_cost: "9.99",
      rate_per_tonne_raw: "9.99",
      rate_per_tonne_rounded: "9.99"
    )
  }

  before(:each) do
    assign(:tender_equipment_summary, tender_equipment_summary)
  end

  it "renders the edit tender_equipment_summary form" do
    render

    assert_select "form[action=?][method=?]", tender_equipment_summary_path(tender_equipment_summary), "post" do

      assert_select "input[name=?]", "tender_equipment_summary[tender_id]"

      assert_select "input[name=?]", "tender_equipment_summary[equipment_subtotal]"

      assert_select "input[name=?]", "tender_equipment_summary[mobilization_fee]"

      assert_select "input[name=?]", "tender_equipment_summary[total_equipment_cost]"

      assert_select "input[name=?]", "tender_equipment_summary[rate_per_tonne_raw]"

      assert_select "input[name=?]", "tender_equipment_summary[rate_per_tonne_rounded]"
    end
  end
end
