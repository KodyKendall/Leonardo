require 'rails_helper'

RSpec.describe "tenders/edit", type: :view do
  let(:tender) { create(:tender) }

  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @clients = [create(:client), create(:client)]
    assign(:clients, @clients)
    assign(:tender, tender)
  end

  it "renders the edit tender form" do
    render

    assert_select "form[action=?][method=?]", tender_path(tender), "post" do
      assert_select "input[name=?]", "tender[tender_name]"
      assert_select "textarea[name=?]", "tender[notes]"
    end
  end
end
