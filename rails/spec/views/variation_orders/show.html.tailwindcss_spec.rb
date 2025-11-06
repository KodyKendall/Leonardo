require 'rails_helper'

RSpec.describe "variation_orders/show", type: :view do
  before(:each) do
    assign(:variation_order, VariationOrder.create!(
      vo_number: "Vo Number",
      project: nil,
      vo_status: "Vo Status",
      vo_amount: "9.99",
      description: "MyText",
      created_by: nil,
      approved_by: nil,
      approver_notes: "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Vo Number/)
    expect(rendered).to match(//)
    expect(rendered).to match(/Vo Status/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/MyText/)
  end
end
