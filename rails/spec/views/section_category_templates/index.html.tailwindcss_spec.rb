require 'rails_helper'

RSpec.describe "section_category_templates/index", type: :view do
  before(:each) do
    assign(:section_category_templates, [
      SectionCategoryTemplate.create!(
        section_category: nil
      ),
      SectionCategoryTemplate.create!(
        section_category: nil
      )
    ])
  end

  it "renders a list of section_category_templates" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
