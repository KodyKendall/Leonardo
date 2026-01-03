import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit", "indicator"]

  markDirty(event) {
    // Show the dirty indicator when field changes
    this.indicatorTarget.classList.remove("hidden")
    this.submitTarget.classList.add("btn-warning")
    this.submitTarget.classList.remove("btn-primary")
  }

  reset(event) {
    // Hide the dirty indicator after form submission
    this.indicatorTarget.classList.add("hidden")
    this.submitTarget.classList.remove("btn-warning")
    this.submitTarget.classList.add("btn-primary")
  }
}
