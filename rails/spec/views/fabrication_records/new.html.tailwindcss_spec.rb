require 'rails_helper'

RSpec.describe "fabrication_records/new", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:fabrication_record, FabricationRecord.new(
      project: nil,
      tonnes_fabricated: "9.99",
      allowed_rate: "9.99",
      allowed_amount: "9.99",
      actual_spend: "9.99"
    ))
  end

  it "renders new fabrication_record form" do
    render

    assert_select "form[action=?][method=?]", fabrication_records_path, "post" do

      assert_select "input[name=?]", "fabrication_record[project_id]"

      assert_select "input[name=?]", "fabrication_record[tonnes_fabricated]"

      assert_select "input[name=?]", "fabrication_record[allowed_rate]"

      assert_select "input[name=?]", "fabrication_record[allowed_amount]"

      assert_select "input[name=?]", "fabrication_record[actual_spend]"
    end
  end
end
