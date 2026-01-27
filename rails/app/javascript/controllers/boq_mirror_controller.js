import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "button" ]

  submit(event) {
    // Disable the button to prevent multiple clicks
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
      this.buttonTarget.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i> Copying...'
    }
  }
}
