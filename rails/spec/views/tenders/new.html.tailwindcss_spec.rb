require 'rails_helper'

RSpec.describe "tenders/new", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @clients = [create(:client), create(:client)]
    assign(:clients, @clients)
    assign(:tender, Tender.new(
      status: "Draft",
      awarded_project: nil
    ))
  end

  it "renders new tender form" do
    render

    assert_select "form[action=?][method=?]", tenders_path, "post" do
      assert_select "input[name=?]", "tender[tender_name]"
      assert_select "textarea[name=?]", "tender[notes]"
    end
  end
end
