require 'rails_helper'

RSpec.describe "tenders/new", type: :view do
  before(:each) do
    assign(:tender, Tender.new(
      e_number: "MyString",
      status: "MyString",
      client_name: "MyString",
      tender_value: "9.99",
      project_type: "MyString",
      notes: "MyText",
      awarded_project: nil
    ))
  end

  it "renders new tender form" do
    render

    assert_select "form[action=?][method=?]", tenders_path, "post" do

      assert_select "input[name=?]", "tender[e_number]"

      assert_select "input[name=?]", "tender[status]"

      assert_select "input[name=?]", "tender[client_name]"

      assert_select "input[name=?]", "tender[tender_value]"

      assert_select "input[name=?]", "tender[project_type]"

      assert_select "textarea[name=?]", "tender[notes]"

      assert_select "input[name=?]", "tender[awarded_project_id]"
    end
  end
end
