import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "form", "field", "editBtn", "deleteBtn", "unsavedIndicator", "savedIndicator"]
  
  initialize() {
    this.isEditing = false
    this.originalValues = {}
  }

  connect() {
    // Store original field values
    this.fieldTargets.forEach((field) => {
      this.originalValues[field.name] = field.value
    })
  }

  toggleEditMode() {
    this.isEditing ? this.formTarget.requestSubmit() : this.enterEditMode()
  }

  enterEditMode() {
    this.isEditing = true
    
    // Make all fields editable (remove readonly)
    this.fieldTargets.forEach((field) => {
      field.removeAttribute("readonly")
      field.addEventListener("change", this.markDirty.bind(this))
    })

    // Change pencil icon to checkmark on edit button
    const editIcon = this.editBtnTarget.querySelector("[data-inline-edit-target='editIcon']")
    editIcon.classList.remove("fa-pencil")
    editIcon.classList.add("fa-check")
    this.editBtnTarget.classList.remove("btn-outline")
    this.editBtnTarget.classList.add("btn-success")
    
    this.formTarget.classList.add("editing")
  }

  cancelEdit() {
    this.isEditing = false

    // Reset fields to original values and make readonly
    this.fieldTargets.forEach((field) => {
      field.value = this.originalValues[field.name]
      field.setAttribute("readonly", "readonly")
      field.classList.remove("ring-2", "ring-yellow-400")
      field.removeEventListener("change", this.markDirty.bind(this))
    })

    // Change checkmark back to pencil icon
    const editIcon = this.editBtnTarget.querySelector("[data-inline-edit-target='editIcon']")
    editIcon.classList.remove("fa-check")
    editIcon.classList.add("fa-pencil")
    this.editBtnTarget.classList.add("btn-outline")
    this.editBtnTarget.classList.remove("btn-success")
    
    // Remove cancel button
    this.removeCancelButton()
    
    // Hide unsaved alert
    this.hideUnsavedAlert()
    
    this.formTarget.classList.remove("editing")
  }

  addCancelButton() {
    if (document.querySelector("[data-inline-edit-target='cancelBtn']")) return
    
    const cancelBtn = document.createElement("button")
    cancelBtn.type = "button"
    cancelBtn.className = "btn btn-circle btn-ghost btn-sm"
    cancelBtn.title = "Cancel"
    cancelBtn.setAttribute("data-inline-edit-target", "cancelBtn")
    cancelBtn.addEventListener("click", () => this.cancelEdit())
    cancelBtn.innerHTML = '<i class="fas fa-x text-lg"></i>'
    
    this.editBtnTarget.parentNode.insertBefore(cancelBtn, this.editBtnTarget.nextSibling)
  }

  removeCancelButton() {
    const cancelBtn = document.querySelector("[data-inline-edit-target='cancelBtn']")
    if (cancelBtn) {
      cancelBtn.remove()
    }
  }

  markDirty(event) {
    // Add visual indicator for dirty fields
    const field = event.target
    if (field.value !== this.originalValues[field.name]) {
      field.classList.add("ring-2", "ring-yellow-400")
      this.showUnsavedAlert()
    } else {
      field.classList.remove("ring-2", "ring-yellow-400")
      this.checkIfAllClean()
    }
  }

  showUnsavedAlert() {
    if (this.hasUnsavedIndicatorTarget) {
      this.unsavedIndicatorTarget.classList.remove("hidden")
      this.hideSavedAlert()
    }
  }

  hideUnsavedAlert() {
    if (this.hasUnsavedIndicatorTarget) {
      this.unsavedIndicatorTarget.classList.add("hidden")
    }
  }

  showSavedAlert() {
    if (this.hasSavedIndicatorTarget) {
      this.savedIndicatorTarget.classList.remove("hidden")
      // Auto-hide after 3 seconds
      setTimeout(() => {
        this.hideSavedAlert()
      }, 3000)
    }
  }

  hideSavedAlert() {
    if (this.hasSavedIndicatorTarget) {
      this.savedIndicatorTarget.classList.add("hidden")
    }
  }

  checkIfAllClean() {
    const hasChanges = this.fieldTargets.some(field => field.value !== this.originalValues[field.name])
    if (!hasChanges) {
      this.hideUnsavedAlert()
    }
  }

  calculateTotal() {
    // Get quantity, duration_days, and wet_rate_per_day fields
    const quantityField = this.formTarget.querySelector('input[name="tender_crane_selection[quantity]"]')
    const durationField = this.formTarget.querySelector('input[name="tender_crane_selection[duration_days]"]')
    const rateField = this.formTarget.querySelector('input[name="tender_crane_selection[wet_rate_per_day]"]')
    const totalDisplay = this.formTarget.querySelector('[data-total-cost-display]')

    if (quantityField && durationField && rateField && totalDisplay) {
      const qty = parseFloat(quantityField.value) || 0
      const days = parseFloat(durationField.value) || 0
      const rate = parseFloat(rateField.value) || 0
      const total = qty * days * rate

      // Format and display the total cost
      totalDisplay.value = 'R ' + total.toFixed(2)
      
      // Mark as dirty to show unsaved alert
      this.markDirty({ target: quantityField })
    }
  }

}