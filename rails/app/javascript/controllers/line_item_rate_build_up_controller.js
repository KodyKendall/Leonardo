import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form",
    "row",
    "rateInput",
    "includedCheckbox",
    "amountCell",
    "subtotal",
    "marginInput",
    "marginDisplay",
    "beforeRounding",
    "roundedRate",
    "dirtyIndicator",
    "saveButton"
  ]

  connect() {
    this.isDirty = false
    this.initializing = true
    this.calculateDisplay()
    this.initializing = false
  }

  markDirty() {
    if (this.initializing) return

    if (!this.isDirty) {
      this.isDirty = true
      if (this.hasDirtyIndicatorTarget) {
        this.dirtyIndicatorTarget.classList.remove("hidden")
      }
      if (this.hasSaveButtonTarget) {
        this.saveButtonTarget.classList.add("btn-warning")
        this.saveButtonTarget.classList.remove("btn-primary")
      }
    }
  }

  calculate() {
    this.calculateDisplay()
    this.markDirty()
  }

  calculateDisplay() {
    let subtotal = 0

    // Iterate through each row and calculate amounts
    this.rowTargets.forEach((row, index) => {
      const rateInput = this.rateInputTargets[index]
      const checkbox = this.includedCheckboxTargets[index]
      const amountCell = this.amountCellTargets[index]

      if (rateInput && checkbox && amountCell) {
        const rate = parseFloat(rateInput.value) || 0
        const isIncluded = checkbox.checked

        if (isIncluded) {
          subtotal += rate
          amountCell.innerHTML = `<span>R ${rate.toFixed(2)}</span>`
        } else {
          amountCell.innerHTML = `<span class="text-gray-400">—</span>`
        }
      }
    })

    // Update subtotal
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = `R ${subtotal.toFixed(2)}`
    }

    // Get margin
    const margin = this.hasMarginInputTarget ? (parseFloat(this.marginInputTarget.value) || 0) : 0

    // Update margin display
    if (this.hasMarginDisplayTarget) {
      this.marginDisplayTarget.textContent = `R ${margin.toFixed(2)}`
    }

    // Calculate total before rounding
    const totalBeforeRounding = subtotal + margin
    if (this.hasBeforeRoundingTarget) {
      this.beforeRoundingTarget.textContent = `R ${totalBeforeRounding.toFixed(2)}`
    }

    // Round to nearest whole number
    const roundedRate = Math.round(totalBeforeRounding)
    if (this.hasRoundedRateTarget) {
      this.roundedRateTarget.textContent = `R ${roundedRate.toFixed(2)}`
    }
  }
}
