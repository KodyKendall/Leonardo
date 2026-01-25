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
    "saveButton",
    "customRow",
    "customDescription",
    "customIncluded",
    "customRate",
    "customAmount",
    "addButtonRow",
    "destroyField",
    "massCalcRow",
    "massCalcInput"
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

  addCustomItem(event) {
    event.preventDefault()
    
    // Find the button row
    const buttonRow = this.addButtonRowTarget
    if (!buttonRow) return
    
    // Generate a unique timestamp-based key for the nested attribute index
    const timestamp = new Date().getTime()
    
    // Create the HTML for a new custom item row
    const html = `
      <tr class="hover:bg-base-200 border-t-2 border-orange-200 bg-orange-50"
          data-line-item-rate-build-up-target="customRow"
          data-new-item="true">
        <td class="font-medium">
          <input type="text"
                 name="line_item_rate_build_up[rate_buildup_custom_items_attributes][${timestamp}][description]"
                 placeholder="e.g., Special Coating"
                 class="input input-sm input-bordered w-full"
                 data-controller="autoselect"
                 data-action="focus->autoselect#select"
                 data-line-item-rate-build-up-target="customDescription" />
        </td>
        <td class="text-center">
          <input type="number"
                 name="line_item_rate_build_up[rate_buildup_custom_items_attributes][${timestamp}][included]"
                 step="0.01"
                 min="0.01"
                 value="1.0"
                 placeholder="1.0"
                 class="input input-sm input-bordered w-20 text-center"
                 data-controller="autoselect"
                 data-action="focus->autoselect#select"
                 data-line-item-rate-build-up-target="customIncluded" />
        </td>
        <td class="text-right">
          <input type="number"
                 name="line_item_rate_build_up[rate_buildup_custom_items_attributes][${timestamp}][rate]"
                 step="0.01"
                 min="0"
                 placeholder="0.00"
                 class="input input-sm input-bordered w-28 text-right"
                 data-controller="autoselect"
                 data-action="focus->autoselect#select"
                 data-line-item-rate-build-up-target="customRate" />
        </td>
        <td class="text-right font-semibold" data-line-item-rate-build-up-target="customAmount">—</td>
        <td class="text-center">
          <button type="button"
                  class="btn btn-sm btn-ghost text-red-500 hover:text-red-700"
                  data-action="click->line-item-rate-build-up#removeCustomItem">
            <i class="fas fa-trash"></i>
          </button>
          <input type="hidden"
                 name="line_item_rate_build_up[rate_buildup_custom_items_attributes][${timestamp}][_destroy]"
                 value="false"
                 data-line-item-rate-build-up-target="destroyField" />
        </td>
      </tr>
    `
    
    // Insert the new row before the button row
    buttonRow.insertAdjacentHTML('beforebegin', html)
    
    // Focus on the description field of the new row
    const newRows = this.customRowTargets
    if (newRows.length > 0) {
      const lastNewRow = newRows[newRows.length - 1]
      const descriptionInput = lastNewRow.querySelector('[data-line-item-rate-build-up-target="customDescription"]')
      if (descriptionInput) {
        descriptionInput.focus()
      }
    }
    
    this.checkDirtyState()
  }

  toggleMassCalc(event) {
    event.preventDefault()
    this.massCalcRowTarget.classList.toggle('hidden')
    if (!this.massCalcRowTarget.classList.contains('hidden')) {
      this.massCalcInputTarget.focus()
    }
  }

  removeCustomItem(event) {
    event.preventDefault()
    
    const row = event.target.closest('tr[data-line-item-rate-build-up-target="customRow"]')
    if (!row) return
    
    // Check if this is a newly added (unsaved) item
    if (row.hasAttribute('data-new-item')) {
      // Just remove the row from the DOM
      row.remove()
    } else {
      // For saved items, mark for deletion using the _destroy field
      const destroyField = row.querySelector('[data-line-item-rate-build-up-target="destroyField"]')
      if (destroyField) {
        destroyField.value = "true"
        // Hide the row and add visual indication
        row.classList.add('opacity-50', 'line-through')
        row.style.display = 'none'
      }
    }
    
    this.checkDirtyState()
  }
}
