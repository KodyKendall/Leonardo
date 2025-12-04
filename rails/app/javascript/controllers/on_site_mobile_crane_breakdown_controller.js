import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editButton", "field", "submitBtn"]

  connect() {
    this.isEditMode = false
  }

  toggleEdit() {
    if (this.isEditMode) {
      // If in edit mode, submit the form instead of just toggling
      this.submitForm()
    } else {
      // If in view mode, enter edit mode
      this.isEditMode = true
      this.updateEditMode()
    }
  }

  submitForm() {
    // Find the form and submit it
    const form = this.element.closest('form')
    if (form) {
      form.requestSubmit()
    }
  }

  updateEditMode() {
    // Toggle field readonly state
    this.fieldTargets.forEach(field => {
      if (this.isEditMode) {
        // Remove readonly to enable editing
        field.removeAttribute('readonly')
        field.classList.remove('read-only-field')
      } else {
        // Add readonly to disable editing
        field.setAttribute('readonly', 'readonly')
        field.classList.add('read-only-field')
      }
    })

    // Update button icon and color
    if (this.hasEditButtonTarget) {
      if (this.isEditMode) {
        // Checkmark mode - ready to save
        this.editButtonTarget.innerHTML = '<i class="fa fa-check"></i>'
        this.editButtonTarget.classList.remove('btn-ghost')
        this.editButtonTarget.classList.add('btn-success')
      } else {
        // Pencil mode - ready to edit
        this.editButtonTarget.innerHTML = '<i class="fa fa-pencil"></i>'
        this.editButtonTarget.classList.remove('btn-success')
        this.editButtonTarget.classList.add('btn-ghost')
      }
    }

    // Update submit button visibility
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.classList.toggle('hidden', !this.isEditMode)
    }
  }

  // Called by dirty-form controller after successful save
  reset() {
    this.isEditMode = false
    this.updateEditMode()
  }
}
