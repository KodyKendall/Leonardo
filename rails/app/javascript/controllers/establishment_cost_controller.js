import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit", "indicator"]

  markDirty(event) {
    // Show the dirty indicator and submit button when field changes
    this.indicatorTarget.classList.remove("hidden")
    this.submitTarget.classList.remove("hidden")
  }

  reset(event) {
    // Hide the dirty indicator and submit button after form submission
    this.indicatorTarget.classList.add("hidden")
    this.submitTarget.classList.add("hidden")
  }
}
