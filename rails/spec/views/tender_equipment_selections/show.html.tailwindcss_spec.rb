require 'rails_helper'

RSpec.describe "tender_equipment_selections/show", type: :view do
  before(:each) do
    assign(:tender_equipment_selection, TenderEquipmentSelection.create!(
      tender: nil,
      equipment_type: nil,
      units_required: 2,
      period_months: 3,
      purpose: "Purpose",
      monthly_cost_override: "9.99",
      calculated_monthly_cost: "9.99",
      total_cost: "9.99",
      sort_order: 4
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/Purpose/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/4/)
  end
end
