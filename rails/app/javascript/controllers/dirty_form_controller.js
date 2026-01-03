import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["indicator", "submit", "savedIndicator"]

  connect() {
    this.form = this.element.tagName === "FORM" ? this.element : this.element.querySelector("form")
    if (!this.form) return

    this.originalData = new FormData(this.form)
    this.isDirty = false
    this.hasValidationErrors = false
    
    // Intercept form submission BEFORE Turbo processes it
    this.form.addEventListener("submit", (e) => this.handleFormSubmit(e), true)
    // Listen for form submission to validate before submit
    this.element.addEventListener("turbo:submit-start", (e) => this.handleSubmitStart(e))
  }

  change() {
    if (!this.form) return
    const currentData = new FormData(this.form)
    this.isDirty = !this.formDataEqual(this.originalData, currentData)
    this.updateIndicator()
    // Hide saved message when user makes new changes
    if (this.hasSavedIndicatorTarget && this.isDirty) {
      this.savedIndicatorTarget.classList.add("hidden")
    }
  }

  updateValidationState() {
    // Check all crane size validators on the form
    this.hasValidationErrors = false
    
    console.log("🪲 dirty-form updateValidationState called")
    const allValidators = this.element.querySelectorAll('[data-controller*="crane-size-validator"]')
    console.log("🪲 Found", allValidators.length, "validators on form")
    
    allValidators.forEach((validatorEl, idx) => {
      const validator = this.application.getControllerForElementAndIdentifier(validatorEl, 'crane-size-validator')
      console.log("🪲 Validator", idx, "found:", !!validator)
      if (validator) {
        const isValid = validator.isFormValid()
        console.log("🪲 Validator", idx, "isFormValid():", isValid)
        if (!isValid) {
          this.hasValidationErrors = true
        }
      }
    })
    
    console.log("🪲 dirty-form hasValidationErrors after check:", this.hasValidationErrors)
    this.updateIndicator()
  }

  handleFormSubmit(event) {
    // Check for validation errors BEFORE Turbo processes the form
    this.updateValidationState()
    
    if (this.hasValidationErrors) {
      event.preventDefault()
      event.stopPropagation()
      return false
    }
  }

  handleSubmitStart(event) {
    // Double-check for validation errors before Turbo submission
    this.updateValidationState()
    
    if (this.hasValidationErrors) {
      event.preventDefault()
      return false
    }
  }

  updateIndicator() {
    if (this.hasIndicatorTarget) {
      this.indicatorTarget.classList.toggle("hidden", !this.isDirty)
    }
    if (this.hasSubmitTarget) {
      // Disable submit button if there are validation errors
      if (this.hasValidationErrors) {
        this.submitTarget.disabled = true
        this.submitTarget.classList.add("btn-disabled")
        this.submitTarget.title = "Please fix validation errors before saving"
      } else {
        this.submitTarget.disabled = false
        this.submitTarget.classList.remove("btn-disabled")
        this.submitTarget.title = ""
      }
      
      this.submitTarget.classList.toggle("btn-warning", this.isDirty && !this.hasValidationErrors)
      this.submitTarget.classList.toggle("btn-primary", !this.isDirty && !this.hasValidationErrors)
    }
  }

  formDataEqual(a, b) {
    const aEntries = [...a.entries()].sort((x, y) => x[0].localeCompare(y[0]))
    const bEntries = [...b.entries()].sort((x, y) => x[0].localeCompare(y[0]))
    return JSON.stringify(aEntries) === JSON.stringify(bEntries)
  }

  handleSubmitEnd(event) {
    // Only show success for successful responses (200-299)
    // Validation errors return 422 with success: false
    if (event.detail.success) {
      this.showSavedState()
    }
  }

  showSaveSuccess() {
    this.showSavedState()
  }

  showSavedState() {
    if (!this.form) return
    this.originalData = new FormData(this.form)
    this.isDirty = false
    this.updateIndicator()
    
    // Show saved confirmation and auto-hide after 5 seconds
    if (this.hasSavedIndicatorTarget) {
      this.savedIndicatorTarget.classList.remove("hidden")
      if (this.hasIndicatorTarget) {
        this.indicatorTarget.classList.add("hidden")
      }
      setTimeout(() => {
        this.savedIndicatorTarget.classList.add("hidden")
      }, 5000)
    }
  }

  reset() {
    this.showSavedState()
  }
}
