import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "materialRow",
    "subtotalDisplay",
    "marginInput",
    "totalDisplay",
    "saveButton"
  ]

  connect() {
    this.calculateTotals()
    this.savedMarginValue = this.marginInputTarget.value

    // Ensure save button starts hidden with opacity
    this.saveButtonTarget.classList.add('opacity-0', 'pointer-events-none')
    this.saveButtonTarget.classList.remove('hidden')

    // Listen for custom events from Turbo Stream
    this.element.addEventListener("material:added", () => this.calculateTotals())
    this.element.addEventListener("material:updated", () => this.calculateTotals())
    this.element.addEventListener("material:deleted", () => this.calculateTotals())

    // Listen for successful form submission to clear dirty state
    this.boundHandleSubmitEnd = this.handleSubmitEnd.bind(this)
    this.element.addEventListener("turbo:submit-end", this.boundHandleSubmitEnd)
  }

  disconnect() {
    this.element.removeEventListener("material:added", () => this.calculateTotals())
    this.element.removeEventListener("material:updated", () => this.calculateTotals())
    this.element.removeEventListener("material:deleted", () => this.calculateTotals())
    this.element.removeEventListener("turbo:submit-end", this.boundHandleSubmitEnd)
  }

  handleSubmitEnd(event) {
    if (event.detail.success) {
      this.clearDirty()
    }
  }

  // Called whenever a material is added, removed, or changed
  recalculate() {
    this.calculateTotals()
  }

  // Mark input as dirty when value changes from saved value
  markDirty() {
    const currentValue = this.marginInputTarget.value.trim()
    const savedValue = this.savedMarginValue.trim()
    const isDirty = currentValue !== savedValue
    
    if (isDirty) {
      this.marginInputTarget.classList.add('border-amber-400', 'border-2')
      this.marginInputTarget.classList.remove('border-gray-300')
      this.saveButtonTarget.classList.remove('opacity-0', 'pointer-events-none')
    } else {
      this.marginInputTarget.classList.remove('border-amber-400', 'border-2')
      this.marginInputTarget.classList.add('border-gray-300')
      this.saveButtonTarget.classList.add('opacity-0', 'pointer-events-none')
    }
  }

  // Clear dirty state after successful save
  clearDirty() {
    this.savedMarginValue = this.marginInputTarget.value
    this.marginInputTarget.classList.remove('border-amber-400', 'border-2')
    this.marginInputTarget.classList.add('border-gray-300')
    this.saveButtonTarget.classList.add('opacity-0', 'pointer-events-none')
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
    const totalBeforeRounding = subtotal + marginAmount

    // Round UP to nearest R50
    const total = Math.ceil(totalBeforeRounding / 50) * 50

    // Update total display
    if (this.hasTotalDisplayTarget) {
      this.totalDisplayTarget.textContent = `R${total.toFixed(2)}`
    }
  }
}
