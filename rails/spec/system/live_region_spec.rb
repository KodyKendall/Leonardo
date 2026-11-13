require "rails_helper"

# The base image's accessibility layer in a real browser (LP-43): skip link, focus ring,
# the live region and window.LlamaA11y.announce, and flash / form-error announcements.
# The layer lives in the llama_bot_rails gem; this app has no accessibility code of its own.
RSpec.describe "Accessibility layer", type: :feature do
  SWITCHES = %i[a11y_skip_link a11y_focus_ring a11y_live_region a11y_field_errors].freeze

  around do |example|
    saved = SWITCHES.to_h { |name| [ name, LlamaBotRails.config[name] ] }
    example.run
  ensure
    saved.each { |name, value| LlamaBotRails.config[name] = value }
  end

  before { Capybara.current_driver = :cuprite }

  def region_text
    page.evaluate_script(%(document.getElementById("llama-live-region").textContent))
  end

  def visible?(selector)
    page.evaluate_script(<<~JS)
      (function () {
        var el = document.querySelector(#{selector.to_json});
        if (!el) return false;
        var r = el.getBoundingClientRect();
        return r.width > 1 && r.height > 1 && r.right > 0 && r.bottom > 0;
      })()
    JS
  end

  # Counts any audio or speech the announcer might make.
  def watch_for_sound
    page.execute_script(<<~JS)
      window.__llamaSpoken = 0;
      if (window.speechSynthesis) window.speechSynthesis.speak = function () { window.__llamaSpoken++; };
    JS
  end

  it "gives a plain page the baseline: language, skip link first, one live region" do
    visit root_path
    expect(page).to have_css("html[lang='en']", visible: :all)
    expect(page).to have_css("#llama-live-region[aria-live='polite']", count: 1, visible: :all)

    page.driver.browser.keyboard.type(:Tab)
    expect(page.evaluate_script("document.activeElement.textContent.trim()")).to eq("Skip to main content")
    expect(visible?(".llama-skip-link")).to be(true)
  end

  it "announces a status message silently and invisibly" do
    visit root_path
    watch_for_sound
    page.execute_script(%(window.LlamaA11y.announce("Saved.")))
    expect(page).to have_css("#llama-live-region", text: "Saved.", visible: :all)
    expect(page.evaluate_script("window.__llamaSpoken")).to eq(0)
    expect(page.evaluate_script("document.querySelectorAll('audio').length")).to eq(0)
    expect(visible?("#llama-live-region")).to be(false)
  end

  it "with the live region off: no region, announce is a harmless no-op, the rest stays" do
    LlamaBotRails.config.a11y_live_region = false
    visit root_path
    expect(page).not_to have_css("#llama-live-region", visible: :all)
    expect { page.execute_script(%(window.LlamaA11y.announce("Saved."))) }.not_to raise_error
    expect(page).to have_css("a.llama-skip-link", visible: :all)
    expect(page.html).to include(":focus-visible")
  end

  it "with the focus ring off: the region and the skip link stay hidden" do
    LlamaBotRails.config.a11y_focus_ring = false
    visit root_path
    page.execute_script(%(window.LlamaA11y.announce("Saved.")))
    expect(page).to have_css("#llama-live-region", text: "Saved.", visible: :all)
    expect(visible?("#llama-live-region")).to be(false)
    expect(visible?(".llama-skip-link")).to be(false)
  end

  it "announces into the app's own polite region when the page has one" do
    visit root_path
    page.execute_script(<<~JS)
      document.getElementById("llama-live-region").remove();
      var mine = document.createElement("div");
      mine.id = "mine"; mine.setAttribute("aria-live", "polite");
      document.body.appendChild(mine);
    JS
    page.execute_script(%(window.LlamaA11y.announce("Saved.")))
    expect(page).to have_css("#mine", text: "Saved.", visible: :all)
  end

  it "loads under the app's CSP with no violation, and defines the announcer" do
    page.driver.browser.evaluate_on_new_document(<<~JS)
      window.__cspViolations = 0;
      document.addEventListener("securitypolicyviolation", function () { window.__cspViolations++; });
    JS
    visit root_path
    expect(page.evaluate_script("typeof window.LlamaA11y.announce")).to eq("function")
    expect(page.evaluate_script("window.__cspViolations")).to eq(0)
  end

  it "announces the flash after a form save redirects" do
    user = create(:user, password: "password123", password_confirmation: "password123")
    visit new_user_session_path
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: "password123"
    find("form#new_user [type=submit], form[action='/users/sign_in'] [type=submit]", match: :first).click
    expect(page).to have_css("#llama-live-region", text: "Signed in successfully.", visible: :all, wait: 5)
  end

  it "says how many fields need attention when a form comes back with errors" do
    # Input only the server rejects: the browser's own validation would block a
    # malformed email before the form is ever sent.
    taken = create(:user)
    visit new_user_registration_path
    fill_in "user[email]", with: taken.email
    fill_in "user[password]", with: "password123"
    fill_in "user[password_confirmation]", with: "password124"
    find("form[action='/users'] [type=submit]", match: :first).click
    expect(page).to have_css("#llama-live-region", text: /fields? need attention/, visible: :all, wait: 5)
  end
end
