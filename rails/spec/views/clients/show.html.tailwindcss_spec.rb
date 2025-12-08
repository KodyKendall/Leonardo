require 'rails_helper'

RSpec.describe "clients/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @client = create(:client)
    assign(:client, @client)
  end

  it "renders attributes in <p>" do
    render
  end
end
