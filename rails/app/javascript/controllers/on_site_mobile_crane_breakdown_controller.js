import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editButton", "field", "submitBtn"]

  connect() {
    // Check if we should keep edit mode active due to validation errors
    const keepEditMode = sessionStorage.getItem("dirty-form:keep-edit-mode")
    if (keepEditMode) {
      sessionStorage.removeItem("dirty-form:keep-edit-mode")
      this.isEditMode = true
    } else {
      this.isEditMode = false
    }
    // Initialize disabled state on page load (view mode by default)
    this.updateEditMode()
    // Attach field visibility listeners for checkboxes
    this.attachFieldVisibilityListeners()
    
    // Listen for validation changes from crane-size-validator
    this.attachValidationListeners()
    
    // Initial validation check to set button state correctly on page load
    setTimeout(() => this.updateSaveButtonState(), 100)
  }

  toggleEdit() {
    if (this.isEditMode) {
      // If in edit mode, submit the form instead of just toggling
      this.submitForm()
    } else {
      // If in view mode, enter edit mode
      this.isEditMode = true
      this.updateEditMode()
      
      // Immediately check validation state after entering edit mode
      setTimeout(() => this.updateSaveButtonState(), 50)
    }
  }

  submitForm() {
    // Find the form and check for validation errors before submitting
    const form = this.element.closest('form')
    if (form) {
      // Get the dirty-form controller to check validation state
      const dirtyFormController = this.application.getControllerForElementAndIdentifier(form, 'dirty-form')
      if (dirtyFormController) {
        // Update validation state
        dirtyFormController.updateValidationState()
        
        // Block submission if there are validation errors
        if (dirtyFormController.hasValidationErrors) {
          return false
        }
      }
      
      // No validation errors, proceed with submission
      form.requestSubmit()
    }
  }

  updateSaveButtonState() {
    // Find the form and get the dirty-form controller to check validation state
    const form = this.element.closest('form')
    if (form) {
      const dirtyFormController = this.application.getControllerForElementAndIdentifier(form, 'dirty-form')
      if (dirtyFormController && this.hasEditButtonTarget) {
        // First, ensure dirty-form controller has checked validation state
        dirtyFormController.updateValidationState()
        
        if (this.isEditMode) {
          // In edit mode - update button based on validation state
          if (dirtyFormController.hasValidationErrors) {
            // Disable the save button (checkmark) if there are validation errors
            this.editButtonTarget.disabled = true
            this.editButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
            this.editButtonTarget.title = "Fix validation errors before saving"
          } else {
            // Enable the save button if no validation errors
            this.editButtonTarget.disabled = false
            this.editButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
            this.editButtonTarget.title = "Save changes"
          }
        }
      }
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
    
    // Update save button state based on validation errors
    this.updateSaveButtonState()
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

  // Attach listeners for crane size validation changes
  attachValidationListeners() {
    const form = this.element.closest('form')
    if (form) {
      // Listen for input changes on crane size fields
      const craneSizeInputs = form.querySelectorAll('[data-crane-size-validator-target="input"]')
      craneSizeInputs.forEach(input => {
        input.addEventListener('input', () => this.updateSaveButtonState())
        input.addEventListener('change', () => this.updateSaveButtonState())
      })
    }
  }

  // Called by dirty-form controller after successful save
  reset() {
    // Check if we should keep edit mode active due to validation errors
    const keepEditMode = sessionStorage.getItem("dirty-form:keep-edit-mode")
    if (keepEditMode) {
      sessionStorage.removeItem("dirty-form:keep-edit-mode")
      // Validation errors exist - keep edit mode active
      this.isEditMode = true
      this.updateEditMode()
    } else {
      // No errors - exit edit mode
      this.isEditMode = false
      this.updateEditMode()
    }
    // Re-attach listeners after Turbo Stream re-renders the partial
    this.attachFieldVisibilityListeners()
  }
}
