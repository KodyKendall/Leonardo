# docker compose exec -it llamapress bundle exec rspec spec/system/install_spec.rb --format documentation

require 'rails_helper'

# The controller branches on navigator.userAgent, which can't be changed after the
# browser boots (and driver #headers= only sets HTTP headers, which nothing reads).
# So each faked device needs its own driver.
#
# The UA must go through the Chrome --user-agent flag in browser_options. Cuprite's
# top-level `user_agent:` option is silently ignored — navigator.userAgent still
# reports HeadlessChrome and the mobile branches never run.
#
# These used to be pinned at Safari 17.2 or newer to step around ApplicationController's
# `allow_browser versions: :modern`, which 406s anything older on every route. That is
# why two years of green CI never caught SupportIncident #344. The controller now names
# a wider set, so the iOS UA below sits BELOW the old cutoff on purpose: if anyone
# restores `:modern`, these specs fail instead of passing around the bug.
IOS_USER_AGENT = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) " \
                 "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1"

ANDROID_USER_AGENT = "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 " \
                     "(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36"

# Deliberately a Macintosh UA: iPadOS 13+ reports one by default. Only maxTouchPoints
# distinguishes an iPad from a real Mac, so this is also the desktop UA — the two cases
# are told apart by touch points alone, which is exactly the bug worth guarding.
MAC_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
                 "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

def register_ua_driver(name, user_agent)
  Capybara.register_driver(name) do |app|
    Capybara::Cuprite::Driver.new(
      app,
      window_size: [1200, 900],
      browser_options: {
        'no-sandbox' => nil,
        'disable-gpu' => nil,
        'disable-dev-shm-usage' => nil,
        'user-agent' => user_agent
      },
      process_timeout: 30,
      timeout: 15,
      headless: !ENV['HEADLESS']&.match?(/^(false|no|0)$/i)
    )
  end
end

register_ua_driver(:cuprite_ios, IOS_USER_AGENT)
register_ua_driver(:cuprite_android, ANDROID_USER_AGENT)
register_ua_driver(:cuprite_desktop, MAC_USER_AGENT)

# Use type: :feature instead of :system to use our Cuprite driver config
# (Rails system tests have driver management issues with Cuprite in Docker)
RSpec.describe "Install", type: :feature do
  after { Capybara.use_default_driver }

  # navigator.maxTouchPoints is read-only, so an iPad is simulated by overriding it
  # before the controller reads it. Runs on every new document in the page.
  def fake_touch_points(count)
    page.driver.browser.page.command(
      "Page.addScriptToEvaluateOnNewDocument",
      source: "Object.defineProperty(navigator, 'maxTouchPoints', { get: () => #{count} })"
    )
  end

  describe "on iPhone" do
    before { Capybara.current_driver = :cuprite_ios }

    it "shows the install button and names the platform" do
      visit install_path

      expect(page).to have_button("Install Mobile App", wait: 10)
      expect(page).to have_text("Detected: iPhone · Safari")
    end

    it "opens the Add to Home Screen walkthrough, since Apple blocks automation" do
      visit install_path
      click_button "Install Mobile App"

      expect(page).to have_text("Add to Home Screen", wait: 10)
      expect(page).to have_text("Open as Web App")
    end

    # The icons have to match what Safari actually shows or the steps are harder to
    # follow, not easier. fa-square-arrow-up does not exist in Font Awesome 6.4 free
    # and a wrong/Pro-only name fails silently as a blank box, so pin the names.
    it "illustrates the steps with the icons Safari itself uses" do
      visit install_path
      click_button "Install Mobile App"

      expect(page).to have_css("i.fa-arrow-up-from-bracket", wait: 10)
      expect(page).to have_css("i.fa-square-plus")
      expect(page).to have_no_css("i.fa-circle-arrow-up")
    end
  end

  # iPadOS 13+ sends a Macintosh UA. Without the maxTouchPoints check an iPad falls
  # through to the desktop branch and is offered a QR code to scan with itself.
  describe "on iPad (reports a Macintosh user agent)" do
    before { Capybara.current_driver = :cuprite_desktop }

    it "is treated as iOS, not as a desktop" do
      fake_touch_points(5)
      visit install_path

      expect(page).to have_button("Install Mobile App", wait: 10)
      expect(page).to have_text("Detected: iPad")
      expect(page).to have_no_css("[data-pwa-install-target='qr'] svg", visible: true)
    end
  end

  describe "on Android Chrome" do
    before { Capybara.current_driver = :cuprite_android }

    it "hides the button until the browser says the app is installable" do
      visit install_path

      expect(page).to have_text("Detected: Android · Chrome", wait: 10)
      expect(page).to have_no_button("Install Mobile App")
      expect(page).to have_text("Open your browser menu")
    end

    it "fires the native install dialog once beforeinstallprompt has fired" do
      visit install_path

      # Stand in for the real event. Chrome only fires it against an installable
      # origin, which the test server isn't.
      page.execute_script(<<~JS)
        window.__promptCalled = false
        const event = new Event("beforeinstallprompt")
        event.prompt = () => { window.__promptCalled = true; return Promise.resolve() }
        event.userChoice = Promise.resolve({ outcome: "accepted" })
        window.dispatchEvent(event)
      JS

      expect(page).to have_button("Install Mobile App", wait: 10)
      click_button "Install Mobile App"

      expect(page.evaluate_script("window.__promptCalled")).to be(true)
      # Accepting the install hides the button.
      expect(page).to have_no_button("Install Mobile App")
    end
  end

  describe "on a desktop" do
    before { Capybara.current_driver = :cuprite_desktop }

    it "shows a QR code to continue on a phone, not an install button" do
      fake_touch_points(0)
      visit install_path

      expect(page).to have_text("Detected: macOS · Chrome", wait: 10)
      expect(page).to have_css("[data-pwa-install-target='qr'] svg")
      expect(page).to have_text("Scan this code with your phone")
      expect(page).to have_no_button("Install Mobile App")
    end

    # Desktop Chrome does fire beforeinstallprompt, but honouring it here would
    # install a desktop app — not what this page is for.
    it "keeps showing the QR code even when the browser offers a desktop install" do
      fake_touch_points(0)
      visit install_path

      page.execute_script(<<~JS)
        const event = new Event("beforeinstallprompt")
        event.prompt = () => Promise.resolve()
        event.userChoice = Promise.resolve({ outcome: "accepted" })
        window.dispatchEvent(event)
      JS

      expect(page).to have_css("[data-pwa-install-target='qr'] svg", wait: 10)
      expect(page).to have_no_button("Install Mobile App")
    end
  end
end
