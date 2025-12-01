import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["indicator", "submit"]

  connect() {
    this.originalData = new FormData(this.element)
    this.isDirty = false
  }

  change() {
    const currentData = new FormData(this.element)
    this.isDirty = !this.formDataEqual(this.originalData, currentData)
    this.updateIndicator()
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

  reset() {
    this.originalData = new FormData(this.element)
    this.isDirty = false
    this.updateIndicator()
  }
}
