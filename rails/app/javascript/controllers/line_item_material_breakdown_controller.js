import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "materialRow",
    "subtotalDisplay",
    "marginInput",
    "totalDisplay"
  ]

  connect() {
    this.calculateTotals()
    
    // Listen for custom events from Turbo Stream
    this.element.addEventListener("material:added", () => this.calculateTotals())
    this.element.addEventListener("material:updated", () => this.calculateTotals())
    this.element.addEventListener("material:deleted", () => this.calculateTotals())
  }

  disconnect() {
    this.element.removeEventListener("material:added", () => this.calculateTotals())
    this.element.removeEventListener("material:updated", () => this.calculateTotals())
    this.element.removeEventListener("material:deleted", () => this.calculateTotals())
  }

  // Called whenever a material is added, removed, or changed
  recalculate() {
    this.calculateTotals()
  }

  calculateTotals() {
    let subtotal = 0

    // Sum all material row totals
    this.materialRowTargets.forEach((row) => {
      const totalCell = row.querySelector('[data-line-item-material-total]')
      if (totalCell) {
        const text = totalCell.textContent.trim()
        const amount = parseFloat(text.replace(/[^\d.-]/g, '')) || 0
        subtotal += amount
      }
    })

    // Update subtotal display
    if (this.hasSubtotalDisplayTarget) {
      this.subtotalDisplayTarget.textContent = `R${subtotal.toFixed(2)}`
    }

    // Get margin percentage
    const marginPercent = this.hasMarginInputTarget ? (parseFloat(this.marginInputTarget.value) || 0) : 0

    // Calculate total with margin
    const marginAmount = subtotal * (marginPercent / 100)
    const total = subtotal + marginAmount

    // Update total display
    if (this.hasTotalDisplayTarget) {
      this.totalDisplayTarget.textContent = `R${total.toFixed(2)}`
    }
  }
}
