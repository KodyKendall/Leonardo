require 'rails_helper'

# Regression for mothership SupportIncident #344 (AgentTask #39).
#
# Rails 7.2 scaffolds `allow_browser versions: :modern` into ApplicationController.
# `:modern` means Safari 17.2+ / Chrome 120+ / Firefox 121+, and anything older gets a
# hard HTTP 406 "browser is not supported" page on EVERY route — sign-in included — so
# the customer's app is not reachable at all from that phone.
#
# Why it stayed invisible: the 406 fires before any view renders, it cannot be
# reproduced from a desktop browser, and our own system specs pinned every fake device
# ABOVE the cutoff. A 2026-08-23 sweep of 129 running customer boxes found 89 of them
# 406ing on /users/sign_in from a stock Samsung Internet 23 phone.
#
# Detection is one request with a phone user agent, checking the status code.
RSpec.describe "allow_browser does not lock out real phones", type: :request do
  # Every one of these is BELOW Rails' `:modern` cutoff and was measured 406ing in the
  # fleet sweep. They must all reach the sign-in page.
  OLD_BUT_REAL_USER_AGENTS = {
    "Samsung Internet 23 (Android 13)" =>
      "Mozilla/5.0 (Linux; Android 13; SAMSUNG SM-S918B) AppleWebKit/537.36 " \
      "(KHTML, like Gecko) SamsungBrowser/23.0 Chrome/115.0.0.0 Mobile Safari/537.36",
    "iOS Safari 16.6" =>
      "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 " \
      "(KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1",
    "iOS Safari 17.0" =>
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 " \
      "(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
    "Android Chrome 108" =>
      "Mozilla/5.0 (Linux; Android 12; Pixel 5) AppleWebKit/537.36 " \
      "(KHTML, like Gecko) Chrome/108.0.0.0 Mobile Safari/537.36"
  }.freeze

  OLD_BUT_REAL_USER_AGENTS.each do |device, user_agent|
    it "serves the sign-in page to #{device}" do
      get new_user_session_path, headers: { "HTTP_USER_AGENT" => user_agent }

      # Assert "not 406" rather than "200": sign-in can legitimately redirect.
      expect(response).not_to have_http_status(:not_acceptable),
        "#{device} got a 406 'browser not supported' page instead of the app. " \
        "ApplicationController's allow_browser versions are too narrow — see SI#344."
    end
  end

  # Belt to the braces above: the specs only cover the browsers we thought to name, so
  # also fail loudly if anyone restores the scaffold default wholesale.
  it "never restores Rails' :modern default in ApplicationController" do
    source = Rails.root.join("app/controllers/application_controller.rb").read

    expect(source).not_to match(/allow_browser\s+versions:\s*:modern/),
      "ApplicationController is back on `allow_browser versions: :modern`, which 406s " \
      "every route for Safari < 17.2 and Chrome < 120. Name the versions explicitly " \
      "instead — see SI#344 and the comment above that line."
  end
end
