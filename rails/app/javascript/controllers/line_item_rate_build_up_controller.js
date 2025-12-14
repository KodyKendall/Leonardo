import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "row",
    "rateInput",
    "includedCheckbox",
    "multiplierInput",
    "amountCell",
    "subtotal",
    "marginInput",
    "marginDisplay",
    "beforeRounding",
    "roundedRate",
    "dirtyIndicator",
    "totalDirtyIndicator",
    "saveButton"
  ]

  connect() {
    // Store initial form state
    this.storeInitialState()
    
    // Find the form inside this element (not a parent)
    const form = this.element.querySelector('form')
    
    if (form) {
      // Listen for input changes on all inputs
      form.addEventListener('input', (e) => {
        this.checkDirtyState()
      })
      form.addEventListener('change', (e) => {
        this.checkDirtyState()
      })
      
      // Reset dirty state after successful save (Turbo Stream response)
      document.addEventListener('turbo:submit-end', (e) => {
        if (e.detail.success) {
          this.storeInitialState()
          this.checkDirtyState()
        }
      })
    }
  }

  storeInitialState() {
    const form = this.element.querySelector('form')
    if (form) {
      this.initialFormData = new FormData(form)
      this.initialState = Object.fromEntries(this.initialFormData)
    }
  }

  checkDirtyState() {
    const form = this.element.querySelector('form')
    if (!form) {
      return
    }

    const currentFormData = new FormData(form)
    const currentState = Object.fromEntries(currentFormData)
    
    // Check if any field has changed from initial state
    const isDirty = JSON.stringify(this.initialState) !== JSON.stringify(currentState)
    
    // Update dirty indicators and button state
    try {
      // Update main dirty indicator text
      if (this.hasDirtyIndicatorTarget) {
        if (isDirty) {
          this.dirtyIndicatorTarget.classList.remove('hidden')
        } else {
          this.dirtyIndicatorTarget.classList.add('hidden')
        }
      } else {
        // Fallback: find it manually
        const indicator = this.element.querySelector('[data-line_item_rate_build_up_target="dirtyIndicator"]')
        if (indicator) {
          if (isDirty) {
            indicator.classList.remove('hidden')
          } else {
            indicator.classList.add('hidden')
          }
        }
      }
      
      // Update button color based on dirty state
      if (this.hasSaveButtonTarget) {
        if (isDirty) {
          this.saveButtonTarget.classList.remove('btn-primary')
          this.saveButtonTarget.classList.add('btn-warning')
        } else {
          this.saveButtonTarget.classList.remove('btn-warning')
          this.saveButtonTarget.classList.add('btn-primary')
        }
      }
      
      // Update asterisk next to "Final Rate:" based on dirty state
      if (this.hasTotalDirtyIndicatorTarget) {
        if (isDirty) {
          this.totalDirtyIndicatorTarget.classList.remove('hidden')
        } else {
          this.totalDirtyIndicatorTarget.classList.add('hidden')
        }
      }
    } catch (e) {
      console.error("Error updating dirty indicator:", e)
    }
  }

  saveOnBlur(event) {
    // Auto-save rate or multiplier field on blur via Turbo
    const form = this.element.closest('form')
    if (form) {
      form.requestSubmit()
    }
  }

  saveOnMarginBlur(event) {
    // Save margin field via Turbo form submission
    const form = this.element.closest('form')
    if (form) {
      form.requestSubmit()
    }
  }
}
