import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dryRate", "dieselRate", "wetRate", "sizeField", "ownershipField", "editBtn", "editIcon", "deleteBtn", "fieldsContainer"]

  connect() {
    this.updateWetRate()
  }

  dryRateChanged() {
    this.updateWetRate()
  }

  dieselRateChanged() {
    this.updateWetRate()
  }

  updateWetRate() {
    const dryRate = parseFloat(this.dryRateTarget.value) || 0
    const dieselRate = parseFloat(this.dieselRateTarget.value) || 0
    const wetRate = dryRate + dieselRate

    this.wetRateTarget.textContent = wetRate.toFixed(2)
  }

  toggleEditMode() {
    const isEditing = this.element.classList.contains("editing")
    
    if (isEditing) {
      this.submitAndExit()
    } else {
      this.enterEditMode()
    }
  }

  enterEditMode() {
    // Make fields editable
    this.sizeFieldTarget.removeAttribute("readonly")
    this.ownershipFieldTarget.removeAttribute("disabled")
    this.dryRateTarget.removeAttribute("readonly")
    this.dieselRateTarget.removeAttribute("readonly")

    // Change edit button icon to checkmark and styling
    this.editIconTarget.className = "fas fa-check text-lg"
    this.editBtnTarget.classList.remove("btn-outline")
    this.editBtnTarget.classList.add("btn-primary")

    // Hide delete button during edit
    this.deleteBtnTarget.classList.add("hidden")

    // Mark as editing
    this.element.classList.add("editing")
  }

  submitAndExit() {
    // Set flag that we're about to save
    sessionStorage.setItem("crane-rate:just-saved", "true")
    
    // Submit the form
    this.element.requestSubmit()
    
    // Exit edit mode after submission
    setTimeout(() => {
      this.exitEditMode()
    }, 500)
  }

  exitEditMode() {
    // Make fields read-only
    this.sizeFieldTarget.setAttribute("readonly", true)
    this.ownershipFieldTarget.setAttribute("disabled", true)
    this.dryRateTarget.setAttribute("readonly", true)
    this.dieselRateTarget.setAttribute("readonly", true)

    // Change edit button icon back to pencil and styling
    this.editIconTarget.className = "fas fa-pencil text-lg"
    this.editBtnTarget.classList.add("btn-outline")
    this.editBtnTarget.classList.remove("btn-primary")

    // Show delete button again
    this.deleteBtnTarget.classList.remove("hidden")

    // Mark as not editing
    this.element.classList.remove("editing")
  }
}
