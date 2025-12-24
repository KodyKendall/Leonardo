import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["saveIndicator"]
  static values = { tenderId: Number }

  connect() {
    console.debug("🪲 TenderInclusionsExclusions: controller connected")
    
    // Track state for each checkbox
    this.checkboxes = new Map() // key: checkbox element, value: { isSaving, abortController, initialState }
    
    this.attachCheckboxListeners()
  }

  attachCheckboxListeners() {
    const checkboxes = this.element.querySelectorAll('input[type="checkbox"]')
    checkboxes.forEach(checkbox => {
      this.checkboxes.set(checkbox, {
        isSaving: false,
        abortController: null,
        initialState: checkbox.checked
      })
      
      checkbox.addEventListener('change', (e) => this.handleCheckboxChange(e))
    })
    console.debug(`🪲 TenderInclusionsExclusions: attached listeners to ${checkboxes.length} checkboxes`)
  }

  handleCheckboxChange(event) {
    const checkbox = event.target
    const state = this.checkboxes.get(checkbox)
    
    if (!state) return
    
    console.debug(`🪲 TenderInclusionsExclusions: checkbox changed, field=${checkbox.dataset.fieldName}, checked=${checkbox.checked}`)
    
    // Save immediately (no debounce for checkboxes)
    this.saveField(checkbox)
  }

  async saveField(checkbox) {
    const state = this.checkboxes.get(checkbox)
    if (!state || state.isSaving) {
      console.debug(`🪲 TenderInclusionsExclusions: skipping save, already in-flight`)
      return
    }

    const fieldName = checkbox.dataset.fieldName
    const isChecked = checkbox.checked
    const tenderId = this.tenderIdValue

    state.isSaving = true
    state.abortController = new AbortController()

    this.showSaving()

    try {
      const formData = new FormData()
      formData.append(`tender_inclusions_exclusion[${fieldName}]`, isChecked)
      formData.append('authenticity_token', document.querySelector('meta[name="csrf-token"]').content)

      console.debug(`🪲 TenderInclusionsExclusions: PATCH tender ${tenderId}, field=${fieldName}, value=${isChecked}`)

      const response = await fetch(`/tenders/${tenderId}/update_inclusions_exclusions.json`, {
        method: 'PATCH',
        body: formData,
        signal: state.abortController.signal
      })

      if (!response.ok) {
        throw new Error(`Save failed with status ${response.status}`)
      }

      const data = await response.json()
      
      this.showSaved()
      state.initialState = isChecked
      
      // Visual feedback: brief highlight
      checkbox.classList.add('ring-2', 'ring-green-500')
      setTimeout(() => {
        checkbox.classList.remove('ring-2', 'ring-green-500')
      }, 1000)

      console.debug(`🪲 TenderInclusionsExclusions: saved successfully, field=${fieldName}, data=`, data)
    } catch (error) {
      if (error.name === 'AbortError') {
        console.debug(`🪲 TenderInclusionsExclusions: save aborted (user navigated away)`)
      } else {
        console.error(`🪲 TenderInclusionsExclusions: save failed`, error)
        
        // Revert checkbox to previous state
        checkbox.checked = !isChecked
        this.showError(`Failed to save: ${error.message}`)
      }
    } finally {
      state.isSaving = false
      state.abortController = null
    }
  }

  showSaving() {
    if (!this.hasSaveIndicatorTarget) return
    this.saveIndicatorTarget.textContent = '💾 Saving...'
    this.saveIndicatorTarget.classList.remove('text-green-600', 'text-red-600')
    this.saveIndicatorTarget.classList.add('text-gray-500')
  }

  showSaved() {
    if (!this.hasSaveIndicatorTarget) return
    this.saveIndicatorTarget.textContent = '✅ Saved'
    this.saveIndicatorTarget.classList.remove('text-gray-500', 'text-red-600')
    this.saveIndicatorTarget.classList.add('text-green-600')
    setTimeout(() => {
      this.saveIndicatorTarget.textContent = ''
    }, 2000)
  }

  showError(message) {
    if (!this.hasSaveIndicatorTarget) return
    this.saveIndicatorTarget.textContent = '❌ ' + message
    this.saveIndicatorTarget.classList.remove('text-green-600', 'text-gray-500')
    this.saveIndicatorTarget.classList.add('text-red-600')
  }
}
