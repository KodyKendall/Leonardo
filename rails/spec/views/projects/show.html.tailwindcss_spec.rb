require 'rails_helper'

RSpec.describe "projects/show", type: :view do
  before(:each) do
    assign(:project, Project.create!(
      rsb_number: "Rsb Number",
      tender: nil,
      project_status: "Project Status",
      budget_total: "9.99",
      actual_spend: "9.99",
      created_by: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Rsb Number/)
    expect(rendered).to match(//)
    expect(rendered).to match(/Project Status/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(//)
  end
end
