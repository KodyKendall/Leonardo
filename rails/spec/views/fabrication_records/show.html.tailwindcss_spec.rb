require 'rails_helper'

RSpec.describe "fabrication_records/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @fabrication_record = create(:fabrication_record)
    assign(:fabrication_record, @fabrication_record)
  end

  it "renders attributes in <p>" do
    render
  end
end
