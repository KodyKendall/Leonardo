# docker compose exec -it llamapress bundle exec rspec spec/requests/install_spec.rb --format documentation

require 'rails_helper'

RSpec.describe "/install", type: :request do
  describe "GET /install" do
    it "renders a successful response without signing in" do
      get install_url
      expect(response).to be_successful
    end

    it "renders the install button" do
      get install_url
      expect(response.body).to include('data-controller="pwa-install"')
    end

    it "renders a QR code pointing back at the install page" do
      get install_url

      expect(response.body).to include("<svg")
      expect(response.body).to include('data-pwa-install-target="qr"')
    end
  end

  describe "the QR code" do
    it "encodes the absolute install URL, so a phone can scan it" do
      # Decoding the SVG isn't worth it; assert the input instead — the failure mode
      # that matters is encoding a relative path or localhost.
      expect(RQRCode::QRCode).to receive(:new).with("http://www.example.com/install").and_call_original
      get install_url
    end
  end

  describe "GET /manifest.json" do
    subject(:manifest) { JSON.parse(response.body) }

    before { get "/manifest.json" }

    it "renders a successful response" do
      expect(response).to be_successful
    end

    it "is named, and not the Rails boilerplate default" do
      expect(manifest["name"]).to be_present
      expect(manifest["name"]).not_to eq("RailsBasic")
    end

    # These four are what Chromium checks for installability. If any regress,
    # beforeinstallprompt stops firing and the Android install button silently
    # never appears.
    it "declares the fields required for installability" do
      expect(manifest["display"]).to eq("standalone")
      expect(manifest["start_url"]).to eq("/")
      expect(manifest["scope"]).to eq("/")
      expect(manifest["icons"]).to be_present
    end

    it "does not use the boilerplate theme colors" do
      expect(manifest["theme_color"]).not_to eq("red")
      expect(manifest["background_color"]).not_to eq("red")
    end
  end

  describe "GET /service-worker.js" do
    before { get "/service-worker.js" }

    it "renders a successful response" do
      expect(response).to be_successful
    end

    # Chromium requires a service worker with a fetch handler before it will fire
    # beforeinstallprompt. The stock Rails file has every line commented out, so
    # this guards against regressing back to that.
    it "registers a fetch handler" do
      expect(response.body).to match(/^\s*self\.addEventListener\("fetch"/)
    end
  end
end
