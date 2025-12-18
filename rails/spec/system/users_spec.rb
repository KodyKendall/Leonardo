# docker compose exec -it llamapress bundle exec rspec spec/system/users_spec.rb --format documentation

require 'rails_helper'

# Use type: :feature instead of :system to use our Cuprite driver config
# (Rails system tests have driver management issues with Cuprite in Docker)
RSpec.describe "Users", type: :feature do
  let(:user) { create(:user) }

  before do
    Capybara.current_driver = :cuprite
    login_as(user, scope: :user)
  end

  describe "visiting the index" do
    it "displays the users page" do
      visit users_path
      expect(page).to have_selector("h1", text: "Users", wait: 10)
    end
  end
end
