require 'rails_helper'

RSpec.describe "section_category_templates/edit", type: :view do
  let(:section_category_template) {
    SectionCategoryTemplate.create!(
      section_category: nil
    )
  }

  before(:each) do
    assign(:section_category_template, section_category_template)
  end

  it "renders the edit section_category_template form" do
    render

    assert_select "form[action=?][method=?]", section_category_template_path(section_category_template), "post" do

      assert_select "input[name=?]", "section_category_template[section_category_id]"
    end
  end
end
