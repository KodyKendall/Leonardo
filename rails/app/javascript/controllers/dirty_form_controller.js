import { Controller } from "@hotwired/stimulus"

// Tracks form changes and shows an unsaved indicator
export default class extends Controller {
  static targets = ["indicator"]

  connect() {
    this.isDirty = false
    this.element.addEventListener("input", this.markDirty.bind(this))
    this.element.addEventListener("change", this.markDirty.bind(this))
  }

  markDirty() {
    if (!this.isDirty) {
      this.isDirty = true
      this.indicatorTarget.classList.remove("hidden")
    }
  }
}
