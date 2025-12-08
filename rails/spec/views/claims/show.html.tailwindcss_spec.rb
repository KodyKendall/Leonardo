require 'rails_helper'

RSpec.describe "claims/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @claim = create(:claim)
    assign(:claim, @claim)
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/#{@claim.claim_number}/)
    expect(rendered).to match(/#{@claim.claim_status}/)
  end
end
