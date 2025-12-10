import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
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
    "saveButton",
    "materialSupplyInput"
  ]

  connect() {
    this.isDirty = false
    this.initializing = true
    // Use setTimeout to ensure DOM is fully settled after turbo-stream replacement
    setTimeout(() => {
      this.syncMaterialSupplyRate()
      this.calculateDisplay()
      this.initializing = false
      this.observeMaterialBreakdownChanges()
    }, 0)
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  // Sync material supply rate from Material Breakdown total
  syncMaterialSupplyRate() {
    if (!this.hasMaterialSupplyInputTarget) return

    // Find the Material Breakdown total display in the sibling component
    const materialBreakdownTotal = document.querySelector('[data-line-item-material-breakdown-target="totalDisplay"]')
    
    if (materialBreakdownTotal) {
      // Extract the numeric value from "R1234.56" format
      const totalText = materialBreakdownTotal.textContent.trim()
      const numericValue = parseFloat(totalText.replace(/[^\d.-]/g, ''))
      
      if (!isNaN(numericValue)) {
        this.materialSupplyInputTarget.value = numericValue.toFixed(2)
        // Trigger a change event so calculations update
        this.materialSupplyInputTarget.dispatchEvent(new Event('input', { bubbles: true }))
      }
    }
  }

  // Observe Material Breakdown for changes
  observeMaterialBreakdownChanges() {
    const materialBreakdownContainer = document.querySelector('[data-controller="line-item-material-breakdown"]')
    
    if (!materialBreakdownContainer) return

    // Use MutationObserver to watch for changes to the total display
    this.observer = new MutationObserver(() => {
      this.syncMaterialSupplyRate()
    })

    // Watch the totals section for changes
    const totalsSection = materialBreakdownContainer.querySelector('[id^="material_breakdown_totals_"]')
    if (totalsSection) {
      this.observer.observe(totalsSection, {
        subtree: true,
        characterData: true,
        childList: true
      })
    }
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
