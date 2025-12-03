import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "editButton", "deleteButton", "editIcon", "areaDisplay", "areaMinField", "areaMaxField", "fieldsContainer"]
  
  connect() {
    this.isEditing = false
    // Immediately show the fields container
    if (this.hasFieldsContainerTarget) {
      this.fieldsContainerTarget.classList.remove("hidden")
    }
    this.updateUI()
  }
  
  toggleEdit() {
    if (this.isEditing) {
      // Save mode - submit the form (this.element IS the form)
      this.element.requestSubmit()
    } else {
      // Enter edit mode
      this.isEditing = true
      this.updateUI()
    }
  }
  
  updateUI() {
    // Ensure fields container is visible
    if (this.hasFieldsContainerTarget) {
      this.fieldsContainerTarget.classList.remove("hidden")
    }
    
    // Show all fields - no toggling
    if (this.hasAreaDisplayTarget) {
      this.areaDisplayTarget.parentElement.classList.remove("hidden")
    }
    if (this.hasAreaMinFieldTarget) {
      this.areaMinFieldTarget.parentElement.classList.remove("hidden")
    }
    if (this.hasAreaMaxFieldTarget) {
      this.areaMaxFieldTarget.parentElement.classList.remove("hidden")
    }
    
    // Toggle readonly on all other input fields
    this.fieldTargets.forEach(field => {
      field.readOnly = !this.isEditing
    })
    
    // Change icon based on edit mode
    if (this.isEditing) {
      this.editIconTarget.classList.remove("fa-pencil")
      this.editIconTarget.classList.add("fa-check")
      this.deleteButtonTarget.classList.add("hidden")
    } else {
      this.editIconTarget.classList.add("fa-pencil")
      this.editIconTarget.classList.remove("fa-check")
      this.deleteButtonTarget.classList.remove("hidden")
    }
  }
  
  resetAfterSave() {
    this.isEditing = false
    this.updateUI()
  }
}
