require 'rails_helper'

RSpec.describe "tender_equipment_summaries/show", type: :view do
  before(:each) do
    assign(:tender_equipment_summary, TenderEquipmentSummary.create!(
      tender: nil,
      equipment_subtotal: "9.99",
      mobilization_fee: "9.99",
      total_equipment_cost: "9.99",
      rate_per_tonne_raw: "9.99",
      rate_per_tonne_rounded: "9.99"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
  end
end
