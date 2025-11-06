require 'rails_helper'

RSpec.describe "tenders/index", type: :view do
  before(:each) do
    assign(:tenders, [
      Tender.create!(
        e_number: "E Number",
        status: "Status",
        client_name: "Client Name",
        tender_value: "9.99",
        project_type: "Project Type",
        notes: "MyText",
        awarded_project: nil
      ),
      Tender.create!(
        e_number: "E Number",
        status: "Status",
        client_name: "Client Name",
        tender_value: "9.99",
        project_type: "Project Type",
        notes: "MyText",
        awarded_project: nil
      )
    ])
  end

  it "renders a list of tenders" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("E Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Status".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Client Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Project Type".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
