require 'rails_helper'

RSpec.describe "projects/index", type: :view do
  before(:each) do
    assign(:projects, [
      Project.create!(
        rsb_number: "Rsb Number",
        tender: nil,
        project_status: "Project Status",
        budget_total: "9.99",
        actual_spend: "9.99",
        created_by: nil
      ),
      Project.create!(
        rsb_number: "Rsb Number",
        tender: nil,
        project_status: "Project Status",
        budget_total: "9.99",
        actual_spend: "9.99",
        created_by: nil
      )
    ])
  end

  it "renders a list of projects" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Rsb Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Project Status".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
