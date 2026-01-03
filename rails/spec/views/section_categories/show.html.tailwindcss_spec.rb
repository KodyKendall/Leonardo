require 'rails_helper'

RSpec.describe "section_categories/show", type: :view do
  before(:each) do
    assign(:section_category, SectionCategory.create!(
      name: "Name",
      display_name: "Display Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Display Name/)
  end
end
