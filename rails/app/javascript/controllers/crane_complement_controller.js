import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "editButton", "deleteButton"]
  
  connect() {
    this.isEditing = false
    this.updateUI()
  }
  
  toggleEdit() {
    if (this.isEditing) {
      // Save mode - submit the form
      this.element.querySelector("form").requestSubmit()
    } else {
      // Enter edit mode
      this.isEditing = true
      this.updateUI()
    }
  }
  
  updateUI() {
    // Enable/disable all input fields
    this.fieldTargets.forEach(field => {
      field.disabled = !this.isEditing
    })
    
    // Change icon and styling based on edit mode
    const icon = this.editButtonTarget.querySelector("i")
    if (this.isEditing) {
      icon.classList.remove("fa-pencil")
      icon.classList.add("fa-check")
      this.deleteButtonTarget.classList.add("hidden")
    } else {
      icon.classList.add("fa-pencil")
      icon.classList.remove("fa-check")
      this.deleteButtonTarget.classList.remove("hidden")
    }
  }
  
  resetAfterSave() {
    this.isEditing = false
    this.updateUI()
  }
}
