require 'rails_helper'

RSpec.describe "fabrication_records/edit", type: :view do
  let(:fabrication_record) { create(:fabrication_record) }

  before(:each) do
    @user = create(:user)
    sign_in(@user)
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
