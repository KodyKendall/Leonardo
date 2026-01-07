import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "form", "field", "editBtn", "deleteBtn", "unsavedIndicator", "savedIndicator"]
  
  initialize() {
    this.isEditing = false
    this.originalValues = {}
    this.isSubmitting = false
  }

  connect() {
    this.element.classList.add("group") // Ensure group class for CSS-driven UI
    
    // Store original field values
    this.fieldTargets.forEach((field) => {
      this.originalValues[field.name] = field.value
    })

    // Listen for Turbo form submission events
    this.formTarget.addEventListener("turbo:submit-end", (event) => this.onSubmitEnd(event))

    // If it was just saved (passed from server), start the auto-hide timer
    if (this.hasSavedIndicatorTarget && !this.savedIndicatorTarget.classList.contains("hidden")) {
      setTimeout(() => {
        this.hideSavedAlert()
      }, 3000)
    }
  }

  toggleEditMode() {
    if (this.isEditing && !this.isSubmitting) {
      this.isSubmitting = true
      this.formTarget.requestSubmit()
    } else if (!this.isEditing) {
      this.enterEditMode()
    }
  }

  enterEditMode() {
    this.isEditing = true
    this.element.classList.add("is-editing")
    
    // Make all fields editable (remove readonly)
    this.fieldTargets.forEach((field) => {
      if (field.getAttribute("readonly") !== null) {
        field.removeAttribute("readonly")
      }
      field.addEventListener("input", this.markDirty.bind(this))
    })
    
    this.addCancelButton()
  }

  onSubmitEnd(event) {
    this.isSubmitting = false

    if (event.detail.success) {
      // Submission was successful
      // If Turbo Stream replaces the row, this controller instance will disconnect.
      // But we call exitEditMode just in case it doesn't or for non-stream responses.
      this.showSavedAlert()
      this.exitEditMode()
    } else {
      // Submission failed, show error and keep in edit mode
      console.warn("Form submission failed")
    }
  }

  exitEditMode() {
    this.isEditing = false
    this.element.classList.remove("is-editing")

    // Reset fields to original values (if canceled or if we want to revert on failure)
    // Actually, if we just saved, we want to update originalValues.
    // If we are exiting after success, the field.value is already correct.
    this.fieldTargets.forEach((field) => {
      field.setAttribute("readonly", "readonly")
      field.classList.remove("ring-2", "ring-yellow-400")
      field.removeEventListener("input", this.markDirty.bind(this))
      
      // Update original values to current values upon successful exit
      this.originalValues[field.name] = field.value
    })

    // Remove cancel button
    this.removeCancelButton()
    
    // Hide unsaved alert
    this.hideUnsavedAlert()
  }

  cancelEdit() {
    // Revert to original values before exiting
    this.fieldTargets.forEach((field) => {
      field.value = this.originalValues[field.name]
    })
    this.exitEditMode()
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
    if (this.calculationTimeout) clearTimeout(this.calculationTimeout)
    this.calculationTimeout = setTimeout(() => {
      this.performCalculation()
    }, 50)
  }

  performCalculation() {
    // Cache fields if not already cached
    if (!this.quantityField) this.quantityField = this.fieldTargets.find(f => f.name === 'tender_crane_selection[quantity]')
    if (!this.durationField) this.durationField = this.fieldTargets.find(f => f.name === 'tender_crane_selection[duration_days]')
    if (!this.rateField) this.rateField = this.fieldTargets.find(f => f.name === 'tender_crane_selection[wet_rate_per_day]')
    if (!this.totalDisplay) this.totalDisplay = this.formTarget.querySelector('[data-total-cost-display]')

    if (this.quantityField && this.durationField && this.rateField && this.totalDisplay) {
      const qty = parseFloat(this.quantityField.value) || 0
      const days = parseFloat(this.durationField.value) || 0
      const rate = parseFloat(this.rateField.value) || 0
      const total = qty * days * rate

      // Format and display the total cost
      this.totalDisplay.value = 'R ' + total.toFixed(2)
      
      // Mark as dirty to show unsaved alert
      this.markDirty({ target: this.quantityField })
    }
  }

  disconnect() {
    if (this.calculationTimeout) clearTimeout(this.calculationTimeout)
  }

}
