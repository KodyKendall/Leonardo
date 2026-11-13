require "rails_helper"

# LP-43: the accessibility layer rewrites the page body only. Security headers, CSP
# included, must be identical with it on or off.
RSpec.describe "Accessibility layer headers", type: :request do
  around do |example|
    saved = LlamaBotRails.config.inject_accessibility
    example.run
  ensure
    LlamaBotRails.config.inject_accessibility = saved
  end

  def headers_for(enabled)
    LlamaBotRails.config.inject_accessibility = enabled
    get root_path
    response.headers.to_h.slice(
      "Content-Security-Policy", "Content-Security-Policy-Report-Only",
      "X-Frame-Options", "X-Content-Type-Options", "Referrer-Policy", "Permissions-Policy"
    )
  end

  it "leaves the CSP and other security headers unchanged" do
    expect(headers_for(true)).to eq(headers_for(false))
  end

  it "adds the live region on the real layout" do
    LlamaBotRails.config.inject_accessibility = true
    get root_path
    expect(response.body.scan('id="llama-live-region"').size).to eq(1)
  end
end
