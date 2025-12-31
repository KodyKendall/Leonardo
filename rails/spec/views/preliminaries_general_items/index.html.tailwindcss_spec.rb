require 'rails_helper'

RSpec.describe "preliminaries_general_items/index", type: :view do
  before(:each) do
    assign(:preliminaries_general_items, [
      PreliminariesGeneralItem.create!(
        tender: nil,
        category: "Category",
        description: "MyText",
        quantity: "9.99",
        rate: "9.99",
        sort_order: 2
      ),
      PreliminariesGeneralItem.create!(
        tender: nil,
        category: "Category",
        description: "MyText",
        quantity: "9.99",
        rate: "9.99",
        sort_order: 2
      )
    ])
  end

  it "renders a list of preliminaries_general_items" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Category".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
  end
end
