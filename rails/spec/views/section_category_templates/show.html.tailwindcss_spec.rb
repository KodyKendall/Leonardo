require 'rails_helper'

RSpec.describe "section_category_templates/show", type: :view do
  before(:each) do
    assign(:section_category_template, SectionCategoryTemplate.create!(
      section_category: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
  end
end
