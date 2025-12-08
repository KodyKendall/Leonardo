require 'rails_helper'

RSpec.describe "clients/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @clients = [create(:client), create(:client)]
    assign(:clients, @clients)
  end

  it "renders a list of clients" do
    render
  end
end
