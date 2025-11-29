import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rate", "subtotal", "total", "rounded"]
  
  compute() {
    let subtotal = 0
    
    // Get all rate fields and checkboxes
    const rateInputs = this.element.querySelectorAll("[data-rate-calculator-target='rate']")
    
    rateInputs.forEach(input => {
      const fieldName = input.getAttribute("name")
      const baseFieldName = fieldName.replace(/_rate/, "").replace(/[\[\]]/g, "")
      
      // Find corresponding checkbox
      const checkboxName = fieldName.replace(/_rate/, "_included")
      const checkbox = this.element.querySelector(`input[name="${checkboxName}"]`)
      
      // Add rate if included
      if (checkbox && checkbox.checked && input.value) {
        subtotal += parseFloat(input.value) || 0
      } else if (!checkbox && input.value) {
        // If no checkbox, always include
        subtotal += parseFloat(input.value) || 0
      }
    })
    
    // Update subtotal
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.value = subtotal.toFixed(2)
    }
    
    // Get margin amount
    const marginInput = this.element.querySelector("input[name*='margin_amount']")
    const margin = marginInput ? (parseFloat(marginInput.value) || 0) : 0
    
    // Calculate total
    const total = subtotal + margin
    
    if (this.hasTotalTarget) {
      this.totalTarget.value = total.toFixed(2)
    }
    
    // Round to nearest 5 (can be customized)
    if (this.hasRoundedTarget) {
      const roundedValue = Math.ceil(total / 5) * 5
      this.roundedTarget.value = roundedValue.toFixed(2)
    }
  }
}
