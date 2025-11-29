import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.isEditMode = false
    this.updateButtonState()
    this.attachInputListeners()
  }

  attachInputListeners() {
    const inputs = this.element.querySelectorAll('[data-edit-input]')
    inputs.forEach(input => {
      input.addEventListener('change', () => this.handleInputChange(input))
    })
  }

  handleInputChange(input) {
    // Find the form that contains this input
    const form = input.closest('form')
    if (form) {
      // Submit the form via Turbo
      form.requestSubmit()
    }
  }

  toggleEditMode() {
    this.isEditMode = !this.isEditMode
    this.updateInputStates()
    this.updateButtonState()
  }

  updateInputStates() {
    const inputs = this.element.querySelectorAll('[data-edit-input]')
    
    inputs.forEach(input => {
      if (this.isEditMode) {
        input.readOnly = false
        input.classList.remove('opacity-50', 'pointer-events-none')
      } else {
        input.readOnly = true
        input.classList.add('opacity-50', 'pointer-events-none')
      }
    })
  }

  updateButtonState() {
    const button = this.element.querySelector('[data-edit-button]')
    if (!button) return

    if (this.isEditMode) {
      button.innerHTML = '<i class="fas fa-check"></i> Done'
      button.classList.remove('btn-ghost')
      button.classList.add('btn-success')
    } else {
      button.innerHTML = '<i class="fas fa-edit"></i> Edit'
      button.classList.remove('btn-success')
      button.classList.add('btn-ghost')
    }
  }
}
