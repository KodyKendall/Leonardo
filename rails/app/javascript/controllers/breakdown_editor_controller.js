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
    
    if (!this.isEditMode) {
      // Prevent change if not in edit mode
      e.preventDefault()
      e.stopPropagation()
      if (input.type === 'checkbox') {
        input.checked = !input.checked
      }
    } else {
      // If checkbox changed in edit mode, update the amount display live
      if (input.type === 'checkbox') {
        this.updateAmountDisplay(input)
      }
    }
  }

  updateAmountDisplay(checkbox) {
    // Find the parent row
    const row = checkbox.closest('.grid')
    if (!row) return

    // Get the rate value from the rate input in this row
    const rateInput = row.querySelector('input[type="number"]')
    const amountSpan = row.querySelector('.col-span-2.text-right span')
    
    if (!rateInput || !amountSpan) return

    const rateValue = parseFloat(rateInput.value) || 0
    const isChecked = checkbox.checked

    // Update the display
    if (isChecked) {
      amountSpan.textContent = 'R' + rateValue.toFixed(2)
      amountSpan.classList.remove('text-gray-400')
    } else {
      amountSpan.textContent = '—'
      amountSpan.classList.add('text-gray-400')
    }
  }

  toggleEditMode() {
    this.isEditMode = !this.isEditMode
    this.updateInputStates()
    this.updateButtonState()
    console.log('Edit mode toggled:', this.isEditMode)
    
    // If exiting edit mode (clicking "Done"), submit all forms
    if (!this.isEditMode) {
      this.submitAllForms()
    }
  }

  submitAllForms() {
    console.log('Submitting all forms...')
    const forms = this.element.querySelectorAll('form')
    forms.forEach(form => {
      form.requestSubmit()
    })
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
