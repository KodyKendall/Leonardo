import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reset-form"
export default class extends Controller {
  reset(event) {
    if (event.detail.success) {
      this.element.reset()
    }
  }
}
