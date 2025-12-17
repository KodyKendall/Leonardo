import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editButton", "field", "submitBtn"]

  connect() {
    this.isEditMode = false
    // Initialize disabled state on page load (view mode by default)
    this.updateEditMode()
    // Attach field visibility listeners for checkboxes
    this.attachFieldVisibilityListeners()
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
    // Toggle field readonly/disabled state
    this.fieldTargets.forEach(field => {
      if (this.isEditMode) {
        // Remove readonly to enable editing
        field.removeAttribute('readonly')
        field.classList.remove('read-only-field')
        // For checkboxes, remove disabled attribute
        if (field.type === 'checkbox') {
          field.removeAttribute('disabled')
        }
      } else {
        // Add readonly to disable editing
        field.setAttribute('readonly', 'readonly')
        field.classList.add('read-only-field')
        // For checkboxes, add disabled attribute
        if (field.type === 'checkbox') {
          field.setAttribute('disabled', 'disabled')
        }
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

  // Update visibility of dependent fields based on checkbox state
  updateFieldVisibility() {
    const splicingCheckbox = document.getElementById('splicing_crane_required_checkbox')
    const splicingSizeField = document.getElementById('splicing_crane_size_field')
    const splicingDaysField = document.getElementById('splicing_crane_days_field')
    
    const miscCheckbox = document.getElementById('misc_crane_required_checkbox')
    const miscSizeField = document.getElementById('misc_crane_size_field')
    const miscDaysField = document.getElementById('misc_crane_days_field')
    
    if (splicingCheckbox) {
      splicingSizeField.style.display = splicingCheckbox.checked ? 'block' : 'none'
      splicingDaysField.style.display = splicingCheckbox.checked ? 'block' : 'none'
    }
    
    if (miscCheckbox) {
      miscSizeField.style.display = miscCheckbox.checked ? 'block' : 'none'
      miscDaysField.style.display = miscCheckbox.checked ? 'block' : 'none'
    }
  }

  // Attach event listeners for checkbox changes
  attachFieldVisibilityListeners() {
    const splicingCheckbox = document.getElementById('splicing_crane_required_checkbox')
    const miscCheckbox = document.getElementById('misc_crane_required_checkbox')
    
    if (splicingCheckbox) {
      splicingCheckbox.removeEventListener('change', () => this.updateFieldVisibility())
      splicingCheckbox.addEventListener('change', () => this.updateFieldVisibility())
    }
    
    if (miscCheckbox) {
      miscCheckbox.removeEventListener('change', () => this.updateFieldVisibility())
      miscCheckbox.addEventListener('change', () => this.updateFieldVisibility())
    }
  }

  // Called by dirty-form controller after successful save
  reset() {
    this.isEditMode = false
    this.updateEditMode()
    // Re-attach listeners after Turbo Stream re-renders the partial
    this.attachFieldVisibilityListeners()
  }
}
