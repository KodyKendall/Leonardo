require "rails_helper"

# WCAG 2.1 AA check with axe-core (LP-43). Copy this pattern for any new screen:
#
#   visit the_page_path
#   expect(page).to be_axe_clean.according_to(*LlamaBotRails::Testing::Axe::WCAG_TAGS)
#
# llama_bot_rails/testing/axe sets axe up for the image's browser driver (Cuprite) and
# defines the four WCAG tags. The axe gem ships in the base image from 0.7.20; on an
# older image this skips with a message rather than failing. Release acceptance still
# requires 0 skipped.
begin
  require "llama_bot_rails/testing/axe"
rescue LoadError
  nil
end

RSpec.describe "Accessibility (axe, WCAG 2.1 AA)", type: :feature do
  before do
    unless defined?(LlamaBotRails::Testing::Axe)
      skip "axe-core-rspec is not in this image (needs llamapress-simple 0.7.20+)"
    end
    Capybara.current_driver = :cuprite
  end

  it "the home page has no violations when signed in" do
    login_as(create(:user), scope: :user)
    visit root_path
    expect(page).to be_axe_clean.according_to(*LlamaBotRails::Testing::Axe::WCAG_TAGS)
  end
end
