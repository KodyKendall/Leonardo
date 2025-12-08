require 'rails_helper'

RSpec.describe "tenders/show", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    @tender = create(:tender)
    assign(:tender, @tender)
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/#{@tender.e_number}/)
    expect(rendered).to match(/#{@tender.status}/)
    expect(rendered).to match(/#{@tender.tender_value}/)
    expect(rendered).to match(/#{@tender.project_type}/)
  end
end
