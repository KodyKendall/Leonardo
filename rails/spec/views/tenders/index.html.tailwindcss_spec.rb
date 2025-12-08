require 'rails_helper'

RSpec.describe "tenders/index", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
    create(:tender)
    create(:tender)
    @tenders = Tender.all
    assign(:tenders, @tenders)
  end

  it "renders a list of tenders" do
    render
    @tenders.each do |tender|
      expect(rendered).to match(/#{Regexp.escape(tender.e_number)}/)
      expect(rendered).to match(/#{Regexp.escape(tender.status)}/)
    end
  end
end
