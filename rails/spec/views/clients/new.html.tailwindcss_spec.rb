require 'rails_helper'

RSpec.describe "clients/new", type: :view do
  before(:each) do
    assign(:client, Client.new(
      business_name: "MyString",
      contact_name: "MyString",
      contact_email: "MyString"
    ))
  end

  it "renders new client form" do
    render

    assert_select "form[action=?][method=?]", clients_path, "post" do

      assert_select "input[name=?]", "client[business_name]"

      assert_select "input[name=?]", "client[contact_name]"

      assert_select "input[name=?]", "client[contact_email]"
    end
  end
end
