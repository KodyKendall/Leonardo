require 'rails_helper'

RSpec.describe "preliminaries_general_items/edit", type: :view do
  let(:preliminaries_general_item) {
    PreliminariesGeneralItem.create!(
      tender: nil,
      category: "MyString",
      description: "MyText",
      quantity: "9.99",
      rate: "9.99",
      sort_order: 1
    )
  }

  before(:each) do
    assign(:preliminaries_general_item, preliminaries_general_item)
  end

  it "renders the edit preliminaries_general_item form" do
    render

    assert_select "form[action=?][method=?]", preliminaries_general_item_path(preliminaries_general_item), "post" do

      assert_select "input[name=?]", "preliminaries_general_item[tender_id]"

      assert_select "input[name=?]", "preliminaries_general_item[category]"

      assert_select "textarea[name=?]", "preliminaries_general_item[description]"

      assert_select "input[name=?]", "preliminaries_general_item[quantity]"

      assert_select "input[name=?]", "preliminaries_general_item[rate]"

      assert_select "input[name=?]", "preliminaries_general_item[sort_order]"
    end
  end
end
