require 'rails_helper'

RSpec.describe "suppliers/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @suppliers = [create(:supplier), create(:supplier)]
    assign(:suppliers, @suppliers)
  end

  it "renders a list of suppliers" do
    render
  end
end
