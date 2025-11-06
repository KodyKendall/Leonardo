require 'rails_helper'

RSpec.describe "projects/edit", type: :view do
  let(:project) {
    Project.create!(
      rsb_number: "MyString",
      tender: nil,
      project_status: "MyString",
      budget_total: "9.99",
      actual_spend: "9.99",
      created_by: nil
    )
  }

  before(:each) do
    assign(:project, project)
  end

  it "renders the edit project form" do
    render

    assert_select "form[action=?][method=?]", project_path(project), "post" do

      assert_select "input[name=?]", "project[rsb_number]"

      assert_select "input[name=?]", "project[tender_id]"

      assert_select "input[name=?]", "project[project_status]"

      assert_select "input[name=?]", "project[budget_total]"

      assert_select "input[name=?]", "project[actual_spend]"

      assert_select "input[name=?]", "project[created_by_id]"
    end
  end
end
