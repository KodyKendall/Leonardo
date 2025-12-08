require 'rails_helper'

RSpec.describe "clients/edit", type: :view do
  let(:client) { create(:client) }

  before(:each) do
    @user = create(:user)
    sign_in(@user)
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
