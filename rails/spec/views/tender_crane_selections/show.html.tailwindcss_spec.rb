require 'rails_helper'

RSpec.describe "tender_crane_selections/show", type: :view do
  before(:each) do
    assign(:tender_crane_selection, TenderCraneSelection.create!(
      tender: nil,
      crane_rate: nil,
      purpose: "Purpose",
      quantity: 2,
      duration_days: 3,
      wet_rate_per_day: "9.99",
      total_cost: "9.99",
      sort_order: 4
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Purpose/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/4/)
  end
end
