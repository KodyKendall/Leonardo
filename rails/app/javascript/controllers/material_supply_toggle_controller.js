import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    // Find the Material Supply input field in the same rate-row
    const rateRow = event.target.closest(".rate-row")
    const inputField = rateRow.querySelector("input[type='number']")
    
    if (inputField) {
      // Enable/disable based on checkbox state
      inputField.disabled = !event.target.checked
      
      // If disabled, clear the value
      if (inputField.disabled) {
        inputField.value = ""
      }
    }
  }
}
