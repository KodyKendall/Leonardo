import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "indicator"]

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
  }

  formDataEqual(a, b) {
    const aEntries = [...a.entries()].sort((x, y) => x[0].localeCompare(y[0]))
    const bEntries = [...b.entries()].sort((x, y) => x[0].localeCompare(y[0]))
    return JSON.stringify(aEntries) === JSON.stringify(bEntries)
  }
}
