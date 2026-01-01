require 'rails_helper'

RSpec.describe "preliminaries_general_item_templates/new", type: :view do
  before(:each) do
    assign(:preliminaries_general_item_template, PreliminariesGeneralItemTemplate.new(
      category: "MyString",
      description: "MyText",
      quantity: "9.99",
      rate: "9.99",
      sort_order: 1,
      is_crane: false,
      is_access_equipment: false
    ))
  end

  it "renders new preliminaries_general_item_template form" do
    render

    assert_select "form[action=?][method=?]", preliminaries_general_item_templates_path, "post" do

      assert_select "input[name=?]", "preliminaries_general_item_template[category]"

      assert_select "textarea[name=?]", "preliminaries_general_item_template[description]"

      assert_select "input[name=?]", "preliminaries_general_item_template[quantity]"

      assert_select "input[name=?]", "preliminaries_general_item_template[rate]"

      assert_select "input[name=?]", "preliminaries_general_item_template[sort_order]"

      assert_select "input[name=?]", "preliminaries_general_item_template[is_crane]"

      assert_select "input[name=?]", "preliminaries_general_item_template[is_access_equipment]"
    end
  end
end
