import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.isEditMode = false
    this.updateButtonState()
    this.updateInputStates()
    
    // Use event delegation - attach listener to the container
    this.element.addEventListener('change', (e) => this.handleChange(e))
  }

  handleChange(e) {
    const input = e.target
    
    // Only handle inputs with data-edit-input
    if (!input.hasAttribute('data-edit-input')) return
    
    console.log('Input changed:', input.name, 'Edit mode:', this.isEditMode)
    
    if (this.isEditMode) {
      this.handleInputChange(input)
    } else {
      // Prevent change if not in edit mode
      e.preventDefault()
      e.stopPropagation()
      if (input.type === 'checkbox') {
        input.checked = !input.checked
      }
    }
  }

  handleInputChange(input) {
    console.log('Submitting form for:', input.name)
    // Find the form that contains this input
    const form = input.closest('form')
    if (form) {
      console.log('Form found, submitting...')
      // Submit the form via Turbo
      form.requestSubmit()
    } else {
      console.log('No form found for input')
    }
  }

  toggleEditMode() {
    this.isEditMode = !this.isEditMode
    this.updateInputStates()
    this.updateButtonState()
    console.log('Edit mode toggled:', this.isEditMode)
  }

  updateInputStates() {
    const inputs = this.element.querySelectorAll('[data-edit-input]')
    console.log('Updating', inputs.length, 'inputs, edit mode:', this.isEditMode)
    
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
