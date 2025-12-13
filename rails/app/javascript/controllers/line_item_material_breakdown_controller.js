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

  // Handle Enter key to save
  handleKeydown(event) {
    if (event.key === 'Enter') {
      event.preventDefault()
      this.saveMargin()
    }
  }

  // Save margin on explicit checkmark button click or Enter key
  saveMargin() {
    const marginInput = this.marginInputTarget
    const breakdownId = marginInput.getAttribute('data-breakdown-id')
    const marginValue = parseFloat(marginInput.value) || 0

    // Validate margin is between 0-100
    if (marginValue < 0 || marginValue > 100) {
      console.warn('Margin must be between 0 and 100')
      marginInput.classList.add('input-error')
      setTimeout(() => marginInput.classList.remove('input-error'), 1500)
      return
    }

    // Use Turbo's built-in fetch with turbo_stream format
    const form = new FormData()
    form.append('_method', 'PATCH')
    form.append('line_item_material_breakdown[margin_percentage]', marginValue)

    fetch(`/line_item_material_breakdowns/${breakdownId}`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: form
    })
    .then(async response => {
      console.log('Save response status:', response.status, response.ok)
      if (response.ok) {
        // Parse response as turbo stream
        const text = await response.text()
        Turbo.renderStreamMessage(text)
        
        // Clear dirty state on successful save
        this.clearDirty()
        console.log('Dirty state cleared after save')
        
        // Show brief visual feedback (green border flash)
        marginInput.classList.add('input-success')
        setTimeout(() => marginInput.classList.remove('input-success'), 1000)
      } else {
        console.error('Failed to save margin:', response.status)
        // Keep dirty state and show error
        marginInput.classList.add('input-error')
        setTimeout(() => marginInput.classList.remove('input-error'), 1500)
      }
    })
    .catch(error => {
      console.error('Error saving margin:', error)
      // Keep dirty state and show error
      marginInput.classList.add('input-error')
      setTimeout(() => marginInput.classList.remove('input-error'), 1500)
    })
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
