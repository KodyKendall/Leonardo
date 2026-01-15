require 'rails_helper'

RSpec.describe "section_categories/new", type: :view do
  before(:each) do
    assign(:section_category, SectionCategory.new(
      name: "MyString",
      display_name: "MyString"
    ))
  end

  it "renders new section_category form" do
    render

    assert_select "form[action=?][method=?]", section_categories_path, "post" do

      assert_select "input[name=?]", "section_category[name]"

      assert_select "input[name=?]", "section_category[display_name]"
    end
  end
end
