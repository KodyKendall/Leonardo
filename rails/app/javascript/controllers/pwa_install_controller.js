import { Controller } from "@hotwired/stimulus"

/*
 * One "Install Mobile App" button, four outcomes. The split is by *engine*, not by
 * operating system:
 *
 *   Chromium on Android (Chrome, Edge, Samsung, Opera) — beforeinstallprompt lets us
 *     defer the browser's own install UI and fire the real native dialog.
 *   iOS (any browser) — every iOS browser is WebKit and none support that event.
 *     Apple exposes no way to trigger the Add to Home Screen sheet, so we explain it.
 *   Desktop — installing here would produce a desktop app, which isn't what this page
 *     is for. Show a QR code so the phone can finish the job.
 *   Anything else (e.g. Firefox on Android) — generic browser-menu instructions.
 */
export default class extends Controller {
  static targets = [
    "container",
    "button",
    "dialog",
    "instructions",
    "fallback",
    "platform",
    "qr"
  ]

  connect() {
    this.installPrompt = null

    this.beforeInstallPromptHandler = (event) => {
      // Stop Chrome showing its own install UI; we'll trigger it from the button.
      event.preventDefault()
      this.installPrompt = event

      // On desktop the event still fires, but it would install a desktop app — the
      // QR code is the better answer there, so leave the button hidden.
      if (!this.isDesktop()) this.showButton()
    }

    this.appInstalledHandler = () => {
      this.installPrompt = null
      this.showFallback("You've already installed the app.")
    }

    // Bound handlers are stored so disconnect() can remove them. Turbo reconnects
    // controllers on every navigation, so unremoved listeners would stack up.
    window.addEventListener("beforeinstallprompt", this.beforeInstallPromptHandler)
    window.addEventListener("appinstalled", this.appInstalledHandler)

    this.configureInitialState()
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this.beforeInstallPromptHandler)
    window.removeEventListener("appinstalled", this.appInstalledHandler)
  }

  async install() {
    if (this.isInstalled()) {
      this.showFallback("You've already installed the app.")
      return
    }

    // Chromium: launch the native install dialog.
    if (this.installPrompt) {
      await this.installPrompt.prompt()

      const choice = await this.installPrompt.userChoice

      if (choice.outcome === "accepted") {
        this.showFallback("You've already installed the app.")
      }

      // The event is single-use — Chrome fires a fresh one if the user declines.
      this.installPrompt = null
      return
    }

    if (this.isIOS()) {
      this.showIOSInstructions()
      return
    }

    this.showGenericInstructions()
  }

  close() {
    this.dialogTarget.close()
  }

  configureInitialState() {
    this.platformTarget.textContent = `Detected: ${this.describePlatform()}`

    if (this.isInstalled()) {
      this.showFallback("You've already installed the app.")
      return
    }

    // beforeinstallprompt never fires in a cross-origin iframe, and installing the
    // page from inside the LlamaBot builder chrome wouldn't mean anything anyway.
    if (this.isFramed()) {
      this.showFallback("Open this page in a new tab to install the app.")
      return
    }

    if (this.isIOS()) {
      this.showButton()
      return
    }

    if (this.isDesktop()) {
      this.showQRCode()
      return
    }

    /*
     * Android: leave the button hidden until beforeinstallprompt fires. That event is
     * the browser telling us it currently considers the app installable — showing the
     * button before it arrives produces a dead button. Firefox never fires it, hence
     * the menu instructions here.
     */
    this.showFallback("Open your browser menu and choose Install app or Add to Home Screen.")
  }

  showIOSInstructions() {
    const browserWarning = this.isSafari()
      ? ""
      : `<div class="alert alert-warning mb-4">Open this page in Safari first.</div>`

    /*
     * Icons mirror the ones the user is hunting for in Safari's own UI, so they're
     * decorative next to the label — hence aria-hidden.
     *
     * fa-arrow-up-from-bracket is Apple's Share glyph (arrow up out of a square).
     * Font Awesome 6.4 free has no fa-square-arrow-up, and fa-circle-arrow-up is the
     * wrong shape, so don't "fix" this to either of those.
     */
    this.instructionsTarget.innerHTML = `
      ${browserWarning}

      <ol class="list-decimal space-y-3 pl-5">
        <li>
          Tap the <strong>Share</strong> button
          <i class="fa-solid fa-arrow-up-from-bracket mx-1" aria-hidden="true"></i>
          at the bottom of the screen.
        </li>
        <li>
          Scroll down and tap <strong>Add to Home Screen</strong>
          <i class="fa-regular fa-square-plus mx-1" aria-hidden="true"></i>.
        </li>
        <li>Make sure <strong>Open as Web App</strong> is enabled.</li>
        <li>Tap <strong>Add</strong>.</li>
      </ol>
    `

    this.dialogTarget.showModal()
  }

  showGenericInstructions() {
    this.instructionsTarget.innerHTML = `
      <p>
        Open your browser menu and choose <strong>Install app</strong> or
        <strong>Add to Home Screen</strong>.
      </p>
    `

    this.dialogTarget.showModal()
  }

  showButton() {
    this.containerTarget.hidden = false
    this.qrTarget.hidden = true
    this.fallbackTarget.hidden = true
  }

  showQRCode() {
    this.containerTarget.hidden = true
    this.qrTarget.hidden = false
    this.fallbackTarget.textContent = "Scan this code with your phone to install the app there."
    this.fallbackTarget.hidden = false
  }

  showFallback(message) {
    this.containerTarget.hidden = true
    this.qrTarget.hidden = true
    this.fallbackTarget.textContent = message
    this.fallbackTarget.hidden = false
  }

  // A human-readable "iPhone · Safari", shown on the page so a wrong branch is
  // visible instead of mysterious.
  describePlatform() {
    const parts = [this.osName(), this.browserName()]

    if (this.isInstalled()) parts.push("installed")

    return parts.join(" · ")
  }

  osName() {
    const ua = window.navigator.userAgent

    if (/android/i.test(ua)) return "Android"
    if (this.isIOS()) return /ipad/i.test(ua) || this.isIPadOS() ? "iPad" : "iPhone"
    if (/macintosh|mac os x/i.test(ua)) return "macOS"
    if (/windows/i.test(ua)) return "Windows"
    if (/linux/i.test(ua)) return "Linux"

    return "Unknown system"
  }

  browserName() {
    const ua = window.navigator.userAgent

    // Order matters: Chrome's UA contains "Safari", Edge's contains "Chrome", and the
    // iOS browsers below are all WebKit wearing a different name.
    if (/crios/i.test(ua)) return "Chrome"
    if (/fxios/i.test(ua)) return "Firefox"
    if (/edgios|edg\//i.test(ua)) return "Edge"
    if (/opr\/|opios/i.test(ua)) return "Opera"
    if (/samsungbrowser/i.test(ua)) return "Samsung Internet"
    if (/firefox/i.test(ua)) return "Firefox"
    if (/chrome|chromium/i.test(ua)) return "Chrome"
    if (/safari/i.test(ua)) return "Safari"

    return "Unknown browser"
  }

  isInstalled() {
    return (
      window.matchMedia("(display-mode: standalone)").matches ||
      window.navigator.standalone === true
    )
  }

  isFramed() {
    return window.self !== window.top
  }

  isIOS() {
    return /iphone|ipad|ipod/i.test(window.navigator.userAgent) || this.isIPadOS()
  }

  // iPadOS 13+ reports a Macintosh user agent by default, so a plain /ipad/ test
  // misses every modern iPad and treats it as a desktop. Touch points are what
  // separate an iPad from a real Mac.
  isIPadOS() {
    return (
      /macintosh|mac os x/i.test(window.navigator.userAgent) &&
      window.navigator.maxTouchPoints > 1
    )
  }

  isDesktop() {
    return !this.isIOS() && !/android/i.test(window.navigator.userAgent)
  }

  isSafari() {
    const userAgent = window.navigator.userAgent

    return /safari/i.test(userAgent) && !/crios|fxios|edgios|opios/i.test(userAgent)
  }
}
