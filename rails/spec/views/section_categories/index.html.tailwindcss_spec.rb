require 'rails_helper'

RSpec.describe "section_categories/index", type: :view do
  before(:each) do
    assign(:section_categories, [
      SectionCategory.create!(
        name: "Name",
        display_name: "Display Name"
      ),
      SectionCategory.create!(
        name: "Name",
        display_name: "Display Name"
      )
    ])
  end

  it "renders a list of section_categories" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Display Name".to_s), count: 2
  end
end
