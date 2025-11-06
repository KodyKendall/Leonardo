require 'rails_helper'

RSpec.describe "variation_orders/new", type: :view do
  before(:each) do
    assign(:variation_order, VariationOrder.new(
      vo_number: "MyString",
      project: nil,
      vo_status: "MyString",
      vo_amount: "9.99",
      description: "MyText",
      created_by: nil,
      approved_by: nil,
      approver_notes: "MyText"
    ))
  end

  it "renders new variation_order form" do
    render

    assert_select "form[action=?][method=?]", variation_orders_path, "post" do

      assert_select "input[name=?]", "variation_order[vo_number]"

      assert_select "input[name=?]", "variation_order[project_id]"

      assert_select "input[name=?]", "variation_order[vo_status]"

      assert_select "input[name=?]", "variation_order[vo_amount]"

      assert_select "textarea[name=?]", "variation_order[description]"

      assert_select "input[name=?]", "variation_order[created_by_id]"

      assert_select "input[name=?]", "variation_order[approved_by_id]"

      assert_select "textarea[name=?]", "variation_order[approver_notes]"
    end
  end
end
