require 'rails_helper'

RSpec.describe "fabrication_records/edit", type: :view do
  let(:fabrication_record) {
    FabricationRecord.create!(
      project: nil,
      tonnes_fabricated: "9.99",
      allowed_rate: "9.99",
      allowed_amount: "9.99",
      actual_spend: "9.99"
    )
  }

  before(:each) do
    assign(:fabrication_record, fabrication_record)
  end

  it "renders the edit fabrication_record form" do
    render

    assert_select "form[action=?][method=?]", fabrication_record_path(fabrication_record), "post" do

      assert_select "input[name=?]", "fabrication_record[project_id]"

      assert_select "input[name=?]", "fabrication_record[tonnes_fabricated]"

      assert_select "input[name=?]", "fabrication_record[allowed_rate]"

      assert_select "input[name=?]", "fabrication_record[allowed_amount]"

      assert_select "input[name=?]", "fabrication_record[actual_spend]"
    end
  end
end
