import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto-dismiss the toast after 3 seconds
    setTimeout(() => {
      this.element.remove()
    }, 3000)
  }
}
