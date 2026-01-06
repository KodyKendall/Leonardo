require 'rails_helper'

RSpec.describe "section_category_templates/new", type: :view do
  before(:each) do
    assign(:section_category_template, SectionCategoryTemplate.new(
      section_category: nil
    ))
  end

  it "renders new section_category_template form" do
    render

    assert_select "form[action=?][method=?]", section_category_templates_path, "post" do

      assert_select "input[name=?]", "section_category_template[section_category_id]"
    end
  end
end
