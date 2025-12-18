import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "error"]

  connect() {
    console.log("🪲 crane-size-validator connected for element:", this.element)
    this.isValid = true
    this.validate()
  }

  validate() {
    const input = this.inputTarget.value.trim()
    console.log("🪲 crane-size-validator.validate() called. Input value:", input)
    
    // If field is empty and not required, it's valid
    if (!input) {
      this.isValid = true
      this.clearError()
      this.notifyFormOfChange()
      return
    }

    // Check if field is visible (i.e., the corresponding crane is required)
    const fieldContainer = this.element.closest('.form-control')
    if (fieldContainer && fieldContainer.style.display === 'none') {
      console.log("🪲 Field is hidden, marking as valid")
      this.isValid = true
      this.clearError()
      this.notifyFormOfChange()
      return
    }

    // Validate format: number + lowercase 't' (e.g., "30t", "50t")
    const validFormat = /^\d+(\.\d+)?t$/
    
    if (validFormat.test(input)) {
      console.log("🪲 Input is VALID:", input)
      this.isValid = true
      this.clearError()
    } else {
      console.log("🪲 Input is INVALID:", input)
      this.isValid = false
      this.showError(`Invalid format. Use lowercase 't' (e.g., "30t", "50t")`)
    }
    
    // Notify the form controller that validation state changed
    this.notifyFormOfChange()
  }

  clearError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add('hidden')
      this.errorTarget.textContent = ''
    }
    this.inputTarget.classList.remove('input-error')
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.remove('hidden')
      this.errorTarget.textContent = message
    }
    this.inputTarget.classList.add('input-error')
  }

  // Called by dirty-form controller to check if this validator is valid
  isFormValid() {
    return this.isValid
  }

  // Notify the form controller that validation state changed
  notifyFormOfChange() {
    const form = this.element.closest('form')
    if (form) {
      // Trigger change event on the form to update the on-site-mobile-crane-breakdown controller
      const event = new Event('input', { bubbles: true })
      form.dispatchEvent(event)
    }
  }
}
