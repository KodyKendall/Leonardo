require 'rails_helper'

RSpec.describe "clients/show", type: :view do
  before(:each) do
    assign(:client, Client.create!(
      business_name: "Business Name",
      contact_name: "Contact Name",
      contact_email: "Contact Email"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Business Name/)
    expect(rendered).to match(/Contact Name/)
    expect(rendered).to match(/Contact Email/)
  end
end
