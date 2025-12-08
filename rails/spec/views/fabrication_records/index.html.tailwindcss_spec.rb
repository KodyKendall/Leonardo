require 'rails_helper'

RSpec.describe "fabrication_records/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @fabrication_records = [create(:fabrication_record), create(:fabrication_record)]
    assign(:fabrication_records, @fabrication_records)
  end

  it "renders a list of fabrication_records" do
    render
  end
end
