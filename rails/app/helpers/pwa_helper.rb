module PwaHelper
  # Inline SVG QR code pointing at the install page, so someone on a desktop can
  # scan it and finish the install on their phone.
  #
  # Rendered server-side with rqrcode (already in the skeleton Gemfile) rather than
  # a JS library or a third-party QR image API: no CDN, no external request, and the
  # URL never leaves the box.
  # `fill` and `color` must be bare hex WITHOUT a leading "#": rqrcode prepends one
  # itself. A named colour like "white" silently becomes fill="#white", which is not a
  # valid colour, so the background rect falls back to black and paints over the whole
  # code — a QR that renders solid black.
  QR_BACKGROUND = "ffffff".freeze
  QR_FOREGROUND = "000000".freeze

  QR_MODULE_SIZE = 4

  # The quiet zone is part of the code, not decoration: the spec requires 4 modules of
  # light border, and iOS Camera won't lock onto a code without one. rqrcode draws none
  # by default (`offset` defaults to 0), which is what made the rendered code unscannable.
  # Padding on the wrapper element does NOT count — it's in CSS pixels, so it stops being
  # 4 modules as soon as the code is resized.
  QR_QUIET_ZONE = 4 * QR_MODULE_SIZE

  def install_qr_code_svg(url = install_url)
    RQRCode::QRCode.new(url).as_svg(
      module_size: QR_MODULE_SIZE,
      offset: QR_QUIET_ZONE,
      standalone: true,
      use_path: true,
      viewbox: true,
      fill: QR_BACKGROUND,
      color: QR_FOREGROUND
    ).html_safe
  end
end
