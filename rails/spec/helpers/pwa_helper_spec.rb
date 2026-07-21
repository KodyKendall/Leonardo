# docker compose exec -it llamapress bundle exec rspec spec/helpers/pwa_helper_spec.rb --format documentation

require 'rails_helper'

RSpec.describe PwaHelper, type: :helper do
  describe "#install_qr_code_svg" do
    let(:svg) { helper.install_qr_code_svg("https://example.com/install") }

    it "renders an svg" do
      expect(svg).to include("<svg")
      expect(svg).to include("viewBox")
    end

    # Regression guard. rqrcode prepends "#" to whatever it's given, so `fill: "white"`
    # rendered fill="#white" — not a valid colour, so the background rect fell back to
    # black and painted over the entire code. Asserting the <svg> tag exists does not
    # catch this: the markup is present and well-formed, it's just unscannable.
    it "uses only valid hex colours" do
      colours = svg.scan(/fill="([^"]*)"/).flatten

      expect(colours).not_to be_empty
      expect(colours).to all(match(/\A#(\h{3}|\h{6})\z/))
    end

    # The other half of "scannable". A QR code is only valid with a 4-module light
    # border around it; without one, scanners can't find the finder patterns and iOS
    # Camera in particular just refuses to lock on. CSS padding on the wrapper div is
    # not a substitute — the quiet zone has to be inside the image, sized in modules,
    # or it stops being a quiet zone the moment the code is resized.
    it "surrounds the code with a 4-module quiet zone" do
      modules = RQRCode::QRCode.new("https://example.com/install").modules.size
      side = svg[/viewBox="0 0 (\d+) \d+"/, 1].to_i
      quiet_zone = (side - modules * described_class::QR_MODULE_SIZE) / 2

      expect(quiet_zone).to eq(4 * described_class::QR_MODULE_SIZE)
    end

    it "draws dark modules on a light background, so it can actually be scanned" do
      expect(svg).to include(%(fill="##{described_class::QR_BACKGROUND}"))
      expect(svg).to include(%(fill="##{described_class::QR_FOREGROUND}"))
      expect(described_class::QR_BACKGROUND).not_to eq(described_class::QR_FOREGROUND)
    end
  end
end
