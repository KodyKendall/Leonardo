require 'rails_helper'

RSpec.describe "clients/index", type: :view do
  before(:each) do
    assign(:clients, [
      Client.create!(
        business_name: "Business Name",
        contact_name: "Contact Name",
        contact_email: "Contact Email"
      ),
      Client.create!(
        business_name: "Business Name",
        contact_name: "Contact Name",
        contact_email: "Contact Email"
      )
    ])
  end

  it "renders a list of clients" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Business Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Contact Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Contact Email".to_s), count: 2
  end
end
