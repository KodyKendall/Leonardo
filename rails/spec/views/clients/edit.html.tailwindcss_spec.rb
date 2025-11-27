require 'rails_helper'

RSpec.describe "clients/edit", type: :view do
  let(:client) {
    Client.create!(
      business_name: "MyString",
      contact_name: "MyString",
      contact_email: "MyString"
    )
  }

  before(:each) do
    assign(:client, client)
  end

  it "renders the edit client form" do
    render

    assert_select "form[action=?][method=?]", client_path(client), "post" do

      assert_select "input[name=?]", "client[business_name]"

      assert_select "input[name=?]", "client[contact_name]"

      assert_select "input[name=?]", "client[contact_email]"
    end
  end
end
