import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["indicator", "submit", "savedIndicator"]

  connect() {
    this.originalData = new FormData(this.element)
    this.isDirty = false
    
    // Check if we just saved
    if (sessionStorage.getItem("crane-rate:just-saved")) {
      sessionStorage.removeItem("crane-rate:just-saved")
      this.showSavedState()
    }
    
    // Listen for turbo:submit-end to show saved state
    this.element.addEventListener("turbo:submit-end", (e) => this.handleSubmitEnd(e))
  }

  change() {
    const currentData = new FormData(this.element)
    this.isDirty = !this.formDataEqual(this.originalData, currentData)
    this.updateIndicator()
    // Hide saved message when user makes new changes
    if (this.hasSavedIndicatorTarget && this.isDirty) {
      this.savedIndicatorTarget.classList.add("hidden")
    }
  }

  updateIndicator() {
    if (this.hasIndicatorTarget) {
      this.indicatorTarget.classList.toggle("hidden", !this.isDirty)
    }
    if (this.hasSubmitTarget) {
      this.submitTarget.classList.toggle("btn-warning", this.isDirty)
      this.submitTarget.classList.toggle("btn-primary", !this.isDirty)
    }
  }

  formDataEqual(a, b) {
    const aEntries = [...a.entries()].sort((x, y) => x[0].localeCompare(y[0]))
    const bEntries = [...b.entries()].sort((x, y) => x[0].localeCompare(y[0]))
    return JSON.stringify(aEntries) === JSON.stringify(bEntries)
  }

  handleSubmitEnd(event) {
    // Only show saved state if submission was successful (no errors)
    if (event.detail.success) {
      this.showSavedState()
    }
  }

  showSaveSuccess() {
    this.showSavedState()
  }

  showSavedState() {
    this.originalData = new FormData(this.element)
    this.isDirty = false
    this.updateIndicator()
    
    // Show saved confirmation and auto-hide after 3 seconds
    if (this.hasSavedIndicatorTarget) {
      this.savedIndicatorTarget.classList.remove("hidden")
      this.indicatorTarget.classList.add("hidden")
      setTimeout(() => {
        this.savedIndicatorTarget.classList.add("hidden")
      }, 3000)
    }
  }

  reset() {
    this.showSavedState()
  }
}
