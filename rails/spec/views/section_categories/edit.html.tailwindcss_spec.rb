require 'rails_helper'

RSpec.describe "section_categories/edit", type: :view do
  let(:section_category) {
    SectionCategory.create!(
      name: "MyString",
      display_name: "MyString"
    )
  }

  before(:each) do
    assign(:section_category, section_category)
  end

  it "renders the edit section_category form" do
    render

    assert_select "form[action=?][method=?]", section_category_path(section_category), "post" do

      assert_select "input[name=?]", "section_category[name]"

      assert_select "input[name=?]", "section_category[display_name]"
    end
  end
end
