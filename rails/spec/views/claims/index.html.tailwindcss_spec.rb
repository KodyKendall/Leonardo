require 'rails_helper'

RSpec.describe "claims/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @claims = [create(:claim), create(:claim)]
    assign(:claims, @claims)
  end

  it "renders a list of claims" do
    render
    @claims.each do |claim|
      expect(rendered).to match(/#{Regexp.escape(claim.claim_status)}/)
    end
  end
end
