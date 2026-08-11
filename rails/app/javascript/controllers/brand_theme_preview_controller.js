import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lightButton", "darkButton", "label"]

  connect() {
    this.showLight()
  }

  showLight() {
    this.applyTheme("llamapress", "Light preview")
  }

  showDark() {
    this.applyTheme("llamapress-dark", "Dark preview")
  }

  applyTheme(theme, label) {
    this.element.dataset.theme = theme
    const dark = theme === "llamapress-dark"

    this.lightButtonTarget.classList.toggle("btn-primary", !dark)
    this.lightButtonTarget.classList.toggle("btn-ghost", dark)
    this.darkButtonTarget.classList.toggle("btn-primary", dark)
    this.darkButtonTarget.classList.toggle("btn-ghost", !dark)

    this.lightButtonTarget.setAttribute("aria-pressed", String(!dark))
    this.darkButtonTarget.setAttribute("aria-pressed", String(dark))
    this.labelTarget.textContent = label
  }
}
