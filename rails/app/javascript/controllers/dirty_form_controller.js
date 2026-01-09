import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["indicator", "submit", "savedIndicator"]

  connect() {
    this.form = this.element.tagName === "FORM" ? this.element : this.element.querySelector("form")
    if (!this.form) return

    this.originalData = new FormData(this.form)
    this.isDirty = false
    this.hasValidationErrors = false
    this.updateIndicator()
  }

  change() {
    if (!this.form) return
    const currentData = new FormData(this.form)
    const dirty = !this.formDataEqual(this.originalData, currentData)
    
    if (this.isDirty !== dirty) {
      this.isDirty = dirty
      this.updateIndicator()
    }

    // Hide saved message when user makes new changes
    if (this.hasSavedIndicatorTarget && this.isDirty) {
      this.savedIndicatorTarget.classList.add("hidden")
    }
  }

  updateValidationState() {
    // Check all crane size validators on the form
    let errors = false
    const allValidators = this.element.querySelectorAll('[data-controller*="crane-size-validator"]')
    
    allValidators.forEach((validatorEl) => {
      const validator = this.application.getControllerForElementAndIdentifier(validatorEl, 'crane-size-validator')
      if (validator && !validator.isFormValid()) {
        errors = true
      }
    })
    
    if (this.hasValidationErrors !== errors) {
      this.hasValidationErrors = errors
      this.updateIndicator()
    }
    
    return this.hasValidationErrors
  }

  submit(event) {
    if (this.updateValidationState()) {
      event.preventDefault()
      event.stopPropagation()
      return false
    }
  }

  handleSubmitStart(event) {
    if (this.updateValidationState()) {
      event.preventDefault()
      return false
    }
  }

  updateIndicator() {
    if (this.hasIndicatorTarget) {
      this.indicatorTarget.classList.toggle("hidden", !this.isDirty)
    }

    if (this.hasSubmitTarget) {
      // Always ensure disabled state matches validation state
      this.submitTarget.disabled = this.hasValidationErrors
      this.submitTarget.classList.toggle("btn-disabled", this.hasValidationErrors)
      this.submitTarget.title = this.hasValidationErrors ? "Please fix validation errors before saving" : ""
      
      const shouldBeWarning = this.isDirty && !this.hasValidationErrors
      this.submitTarget.classList.toggle("btn-warning", shouldBeWarning)
      this.submitTarget.classList.toggle("btn-primary", !shouldBeWarning)
    }
  }

  formDataEqual(a, b) {
    const aEntries = [...a.entries()].sort((x, y) => x[0].localeCompare(y[0]))
    const bEntries = [...b.entries()].sort((x, y) => x[0].localeCompare(y[0]))
    return JSON.stringify(aEntries) === JSON.stringify(bEntries)
  }

  handleSubmitEnd(event) {
    // Only show success for successful responses (200-299)
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
