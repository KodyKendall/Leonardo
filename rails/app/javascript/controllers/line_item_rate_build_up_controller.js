import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "row",
    "rateInput",
    "includedCheckbox",
    "multiplierInput",
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
    // Use setTimeout to ensure DOM is fully settled after turbo-stream replacement
    setTimeout(() => {
      this.calculateDisplay()
      this.initializing = false
    }, 0)
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

  updateMarginDisplay() {
    if (this.hasMarginInputTarget && this.hasMarginDisplayTarget) {
      const marginPct = parseFloat(this.marginInputTarget.value) || 0
      this.marginDisplayTarget.textContent = `${marginPct}%`
    }
  }

  calculateDisplay() {
    let subtotal = 0

    // Iterate through each row and calculate amounts
    this.rowTargets.forEach((row, index) => {
      const rateInput = this.rateInputTargets[index]
      const amountCell = this.amountCellTargets[index]

      if (rateInput && amountCell) {
        const rate = parseFloat(rateInput.value) || 0

        // All components now use multiplier inputs (no more checkboxes)
        const multiplierInput = row.querySelector('[data-line-item-rate-build-up-target="multiplierInput"]')

        let componentAmount = 0

        if (multiplierInput) {
          // All components: use multiplier logic
          const multiplier = parseFloat(multiplierInput.value) || 0
          componentAmount = rate * multiplier
          
          if (multiplier > 0) {
            subtotal += componentAmount
            amountCell.innerHTML = `<span>R ${componentAmount.toFixed(2)}</span>`
          } else {
            amountCell.innerHTML = `<span class="text-gray-400">—</span>`
          }
        }
      }
    })

    // Update subtotal
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = `R ${subtotal.toFixed(2)}`
    }

    // Get margin percentage
    const marginPct = this.hasMarginInputTarget ? (parseFloat(this.marginInputTarget.value) || 0) : 0

    // Update margin display (show the percentage, not a dollar amount)
    if (this.hasMarginDisplayTarget) {
      this.marginDisplayTarget.textContent = `${marginPct}%`
    }

    // Calculate total before rounding: subtotal * (1 + marginPct / 100)
    const totalBeforeRounding = subtotal * (1 + marginPct / 100)
    if (this.hasBeforeRoundingTarget) {
      this.beforeRoundingTarget.textContent = `R ${totalBeforeRounding.toFixed(2)}`
    }

    // Round to nearest whole number
    const roundedRate = Math.round(totalBeforeRounding)
    if (this.hasRoundedRateTarget) {
      this.roundedRateTarget.textContent = `R ${roundedRate.toFixed(2)}`
    }
  }

  saveOnMarginBlur(event) {
    // Get the form element (the entire line_item_rate_build_up form)
    const form = this.element.closest('form')
    if (!form) return

    // Submit via PATCH request with Turbo Stream support
    fetch(form.action, {
      method: 'PATCH',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: new FormData(form)
    })
    .then(response => response.text())
    .then(html => {
      // Parse the response HTML which contains turbo-stream elements
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, 'text/html')
      
      // Find each turbo-stream element and apply it
      const streams = doc.querySelectorAll('turbo-stream')
      streams.forEach(stream => {
        // Use Turbo's built-in stream processing by cloning into document
        const clone = document.importNode(stream, true)
        // Append to body so Turbo processes it
        document.body.appendChild(clone)
        // Process happens asynchronously, remove after a tick
        requestAnimationFrame(() => clone.remove())
      })
    })
    .catch(error => console.error('Error saving margin percentage:', error))
  }
}
