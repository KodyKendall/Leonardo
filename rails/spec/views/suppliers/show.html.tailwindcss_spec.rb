require 'rails_helper'

RSpec.describe "suppliers/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @supplier = create(:supplier)
    assign(:supplier, @supplier)
  end

  it "renders attributes in <p>" do
    render
  end
end
