require 'rails_helper'

RSpec.describe "fabrication_records/show", type: :view do
  before(:each) do
    assign(:fabrication_record, FabricationRecord.create!(
      project: nil,
      tonnes_fabricated: "9.99",
      allowed_rate: "9.99",
      allowed_amount: "9.99",
      actual_spend: "9.99"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
  end
end
