require 'rails_helper'

RSpec.describe "boqs/show.html.tailwindcss", type: :view do
  before(:each) do
    @user = create(:user)
    sign_in(@user)
  end
  pending "add some examples to (or delete) #{__FILE__}"
end
