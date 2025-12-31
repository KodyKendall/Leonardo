require 'rails_helper'

RSpec.describe "preliminaries_general_items/new", type: :view do
  before(:each) do
    assign(:preliminaries_general_item, PreliminariesGeneralItem.new(
      tender: nil,
      category: "MyString",
      description: "MyText",
      quantity: "9.99",
      rate: "9.99",
      sort_order: 1
    ))
  end

  it "renders new preliminaries_general_item form" do
    render

    assert_select "form[action=?][method=?]", preliminaries_general_items_path, "post" do

      assert_select "input[name=?]", "preliminaries_general_item[tender_id]"

      assert_select "input[name=?]", "preliminaries_general_item[category]"

      assert_select "textarea[name=?]", "preliminaries_general_item[description]"

      assert_select "input[name=?]", "preliminaries_general_item[quantity]"

      assert_select "input[name=?]", "preliminaries_general_item[rate]"

      assert_select "input[name=?]", "preliminaries_general_item[sort_order]"
    end
  end
end
