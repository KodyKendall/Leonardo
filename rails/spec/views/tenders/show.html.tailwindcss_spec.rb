require 'rails_helper'

RSpec.describe "tenders/show", type: :view do
  before(:each) do
    assign(:tender, Tender.create!(
      e_number: "E Number",
      status: "Status",
      client_name: "Client Name",
      tender_value: "9.99",
      project_type: "Project Type",
      notes: "MyText",
      awarded_project: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/E Number/)
    expect(rendered).to match(/Status/)
    expect(rendered).to match(/Client Name/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/Project Type/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(//)
  end
end
