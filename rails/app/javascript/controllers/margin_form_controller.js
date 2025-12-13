import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submitButton"]

  submitOnEnter(event) {
    if (event.key === 'Enter') {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }

  handleSuccess(event) {
    if (event.detail.success) {
      this.inputTarget.classList.add('input-success')
      setTimeout(() => this.inputTarget.classList.remove('input-success'), 1000)
    }
  }
}
