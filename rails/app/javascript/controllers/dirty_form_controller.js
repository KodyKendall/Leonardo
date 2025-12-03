import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["indicator", "submit", "savedIndicator"]

  connect() {
    this.originalData = new FormData(this.element)
    this.isDirty = false
    
    // Check if we just saved - show success message on fresh form after stream render
    if (sessionStorage.getItem("dirty-form:show-saved")) {
      sessionStorage.removeItem("dirty-form:show-saved")
      // Give the DOM a moment to fully render before showing success
      setTimeout(() => this.showSavedState(), 50)
    }
    
    // Listen for successful form submission
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
    // Turbo Stream responses return success: true for 200-299 status codes
    // The update action renders turbo_stream with status 200 on success
    if (event.detail.success) {
      // Set a flag to show saved state after the Turbo Stream re-renders the form
      sessionStorage.setItem("dirty-form:show-saved", "true")
    }
  }

  showSaveSuccess() {
    this.showSavedState()
  }

  showSavedState() {
    this.originalData = new FormData(this.element)
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
