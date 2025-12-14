import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["saveIndicator", "saveAllButton"]
  static values = { monthlyRateId: Number }

  connect() {
    console.debug("🪲 MaterialSupplyRates: controller connected")
    
    // Store initial state for each input
    this.rateInputs = new Map() // key: input element, value: { saveTimeout, isSaving, abortController }
    this.checkboxes = new Map() // key: checkbox element, value: { isSaving, abortController }
    this.pendingSaves = new Set() // track which inputs have unsaved changes
    
    this.attachInputListeners()
    this.attachCheckboxListeners()
    this.setupUnloadProtection()
    this.initSaveButton()
  }

  attachInputListeners() {
    const inputs = this.element.querySelectorAll('.rate-input')
    inputs.forEach(input => {
      // Initialize per-input state
      this.rateInputs.set(input, {
        saveTimeout: null,
        isSaving: false,
        abortController: null,
        lastSavedValue: input.value || ''
      })
      
      input.addEventListener('blur', (e) => this.handleInputBlur(e))
      input.addEventListener('input', (e) => this.handleInputChange(e))
    })
    console.debug(`🪲 MaterialSupplyRates: attached listeners to ${inputs.length} rate inputs`)
  }

  attachCheckboxListeners() {
    const checkboxes = this.element.querySelectorAll('.winner-checkbox')
    checkboxes.forEach(checkbox => {
      this.checkboxes.set(checkbox, {
        isSaving: false,
        abortController: null,
        initialState: checkbox.checked
      })
      
      checkbox.addEventListener('change', (e) => this.handleCheckboxChange(e))
    })
    console.debug(`🪲 MaterialSupplyRates: attached listeners to ${checkboxes.length} winner checkboxes`)
  }

  setupUnloadProtection() {
    window.addEventListener('beforeunload', (e) => {
      // Abort all in-flight fetches before user leaves
      const inFlight = Array.from(this.rateInputs.values()).filter(state => state.isSaving && state.abortController) ||
                       Array.from(this.checkboxes.values()).filter(state => state.isSaving && state.abortController)
      
      if (inFlight.length > 0) {
        console.debug(`🪲 MaterialSupplyRates: aborting ${inFlight.length} in-flight requests on beforeunload`)
        this.rateInputs.forEach(state => {
          if (state.abortController) state.abortController.abort()
        })
        this.checkboxes.forEach(state => {
          if (state.abortController) state.abortController.abort()
        })
      }

      // Warn user if unsaved changes
      if (this.pendingSaves.size > 0) {
        e.preventDefault()
        e.returnValue = 'You have unsaved changes. Leave anyway?'
      }
    })
  }

  handleInputBlur(event) {
    const input = event.target
    const state = this.rateInputs.get(input)
    
    if (!state) return
    
    // Clear any pending debounce
    clearTimeout(state.saveTimeout)
    
    // Save immediately on blur if value changed
    if (input.value !== state.lastSavedValue) {
      console.debug(`🪲 MaterialSupplyRates: blur on input, saving immediately`)
      this.saveRate(input)
    }
  }

  handleInputChange(event) {
    const input = event.target
    const state = this.rateInputs.get(input)
    
    if (!state) return
    
    // Mark as potentially dirty
    const isDirty = input.value !== state.lastSavedValue
    if (isDirty) {
      this.pendingSaves.add(input)
    } else {
      this.pendingSaves.delete(input)
    }
    
    // Clear existing debounce
    clearTimeout(state.saveTimeout)
    
    // Debounce save: 800ms per input (not shared)
    state.saveTimeout = setTimeout(() => {
      if (input.value !== state.lastSavedValue) {
        console.debug(`🪲 MaterialSupplyRates: debounce fired for input, saving...`)
        this.saveRate(input)
      }
    }, 800)
    
    this.updateSaveButton()
  }

  handleCheckboxChange(event) {
    const checkbox = event.target
    const state = this.checkboxes.get(checkbox)
    
    if (!state) return
    
    // Mark checkbox as dirty
    if (checkbox.checked !== state.initialState) {
      this.pendingSaves.add(checkbox)
    } else {
      this.pendingSaves.delete(checkbox)
    }
    
    // Save immediately (no debounce for checkboxes)
    this.saveCheckbox(checkbox)
    this.updateSaveButton()
  }

  async saveRate(input) {
    const state = this.rateInputs.get(input)
    if (!state || state.isSaving) {
      console.debug(`🪲 MaterialSupplyRates: skipping save, already in-flight for this input`)
      return
    }

    const materialId = input.dataset.materialId
    const supplierId = input.dataset.supplierId
    const monthlyRateId = input.dataset.monthlyRateId
    const rate = input.value
    const rateId = input.dataset.rateId

    // Skip if empty and no existing rate
    if ((!rate || rate === '') && !rateId) {
      console.debug(`🪲 MaterialSupplyRates: skipping save, empty field with no existing rate`)
      return
    }

    state.isSaving = true
    state.abortController = new AbortController()

    this.showSaving()

    try {
      // DELETE case
      if ((!rate || rate === '') && rateId) {
        console.debug(`🪲 MaterialSupplyRates: DELETE rate ${rateId}`)
        
        const response = await fetch(`/material_supply_rates/${rateId}.json`, {
          method: 'DELETE',
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          signal: state.abortController.signal
        })

        if (response.ok) {
          this.showSaved()
          input.dataset.rateId = ''
          input.dataset.lastSavedValue = ''
          state.lastSavedValue = ''
          this.pendingSaves.delete(input)
          
          // Remove checkbox
          const cellDiv = input.parentElement.parentElement
          const existingCheckbox = cellDiv.querySelector('.winner-checkbox')
          if (existingCheckbox) {
            existingCheckbox.remove()
          }
          
          console.debug(`🪲 MaterialSupplyRates: deleted rate successfully`)
        } else {
          throw new Error(`Delete failed with status ${response.status}`)
        }
      } 
      // CREATE or UPDATE case
      else {
        const formData = new FormData()
        formData.append('_method', rateId ? 'PATCH' : 'POST')
        formData.append('material_supply_rate[material_supply_id]', materialId)
        formData.append('material_supply_rate[supplier_id]', supplierId)
        formData.append('material_supply_rate[monthly_material_supply_rate_id]', monthlyRateId)
        formData.append('material_supply_rate[rate]', rate)
        formData.append('material_supply_rate[unit]', 'tonne')
        formData.append('authenticity_token', document.querySelector('meta[name="csrf-token"]').content)

        const url = rateId 
          ? `/material_supply_rates/${rateId}.json`
          : `/material_supply_rates.json`

        console.debug(`🪲 MaterialSupplyRates: ${rateId ? 'UPDATE' : 'CREATE'} rate, materialId=${materialId}, supplierId=${supplierId}, rate=${rate}`)

        const response = await fetch(url, {
          method: 'POST',
          body: formData,
          signal: state.abortController.signal
        })

        if (!response.ok) {
          throw new Error(`Save failed with status ${response.status}`)
        }

        const data = await response.json()
        this.showSaved()
        
        input.classList.add('bg-green-50')
        input.dataset.lastSavedValue = rate
        state.lastSavedValue = rate
        this.pendingSaves.delete(input)
        
        setTimeout(() => input.classList.remove('bg-green-50'), 1000)

        // Update rate ID if new
        if (!rateId && data.id) {
          input.dataset.rateId = data.id
        }

        // Handle checkbox visibility
        const cellDiv = input.parentElement.parentElement
        const existingCheckbox = cellDiv.querySelector('.winner-checkbox')
        const rateValue = parseFloat(rate)

        if (rateValue > 0) {
          if (!existingCheckbox) {
            const currentRateId = input.dataset.rateId
            if (currentRateId) {
              this.addWinnerCheckbox(input, currentRateId)
            }
          }
        } else {
          if (existingCheckbox) {
            existingCheckbox.remove()
          }
        }

        console.debug(`🪲 MaterialSupplyRates: saved rate successfully, rateId=${data.id}`)
      }
    } catch (error) {
      if (error.name === 'AbortError') {
        console.debug(`🪲 MaterialSupplyRates: save aborted (user navigated away)`)
      } else {
        console.error(`🪲 MaterialSupplyRates: save failed`, error)
        this.showError(`Failed to save: ${error.message}`)
      }
    } finally {
      state.isSaving = false
      state.abortController = null
      this.updateSaveButton()
    }
  }

  async saveCheckbox(checkbox) {
    const state = this.checkboxes.get(checkbox)
    if (!state || state.isSaving) {
      console.debug(`🪲 MaterialSupplyRates: skipping checkbox save, already in-flight`)
      return
    }

    const rateId = checkbox.dataset.rateId
    const isChecked = checkbox.checked
    const originalState = state.initialState

    state.isSaving = true
    state.abortController = new AbortController()

    this.showSaving()

    try {
      const formData = new FormData()
      formData.append('_method', 'PATCH')
      formData.append('material_supply_rate[is_winner]', isChecked)
      formData.append('authenticity_token', document.querySelector('meta[name="csrf-token"]').content)

      console.debug(`🪲 MaterialSupplyRates: UPDATE is_winner for rate ${rateId}, checked=${isChecked}`)

      const response = await fetch(`/material_supply_rates/${rateId}.json`, {
        method: 'POST',
        body: formData,
        signal: state.abortController.signal
      })

      if (!response.ok) {
        throw new Error(`Checkbox save failed with status ${response.status}`)
      }

      this.showSaved()
      state.initialState = isChecked
      this.pendingSaves.delete(checkbox)
      
      checkbox.classList.add('ring-2', 'ring-green-500')
      setTimeout(() => {
        checkbox.classList.remove('ring-2', 'ring-green-500')
      }, 1000)

      // Uncheck other checkboxes in same row
      if (isChecked) {
        const row = checkbox.closest('tr')
        const otherCheckboxes = row.querySelectorAll('.winner-checkbox')
        otherCheckboxes.forEach(cb => {
          if (cb !== checkbox && cb.checked) {
            cb.checked = false
            // Update their state
            const cbState = this.checkboxes.get(cb)
            if (cbState) {
              cbState.initialState = false
            }
          }
        })
      }

      console.debug(`🪲 MaterialSupplyRates: checkbox saved successfully`)
    } catch (error) {
      if (error.name === 'AbortError') {
        console.debug(`🪲 MaterialSupplyRates: checkbox save aborted`)
      } else {
        console.error(`🪲 MaterialSupplyRates: checkbox save failed`, error)
        checkbox.checked = !isChecked
        this.showError(`Failed to save winner selection: ${error.message}`)
      }
    } finally {
      state.isSaving = false
      state.abortController = null
      this.updateSaveButton()
    }
  }

  addWinnerCheckbox(input, rateId) {
    const container = input.parentElement.parentElement
    const checkbox = document.createElement('input')
    checkbox.type = 'checkbox'
    checkbox.className = 'winner-checkbox w-4 h-4 cursor-pointer'
    checkbox.dataset.rateId = rateId
    checkbox.dataset.materialId = input.dataset.materialId
    checkbox.dataset.supplierId = input.dataset.supplierId
    checkbox.dataset.monthlyRateId = input.dataset.monthlyRateId
    checkbox.title = 'Select as winning supplier for this material'

    // Add to state tracking
    this.checkboxes.set(checkbox, {
      isSaving: false,
      abortController: null,
      initialState: false
    })

    checkbox.addEventListener('change', (e) => this.handleCheckboxChange(e))
    container.appendChild(checkbox)
    console.debug(`🪲 MaterialSupplyRates: created new checkbox for rate ${rateId}`)
  }

  updateSaveButton() {
    if (!this.hasSaveAllButtonTarget) return

    const unsavedCount = this.pendingSaves.size
    const isAnyInFlight = Array.from(this.rateInputs.values()).some(s => s.isSaving) ||
                         Array.from(this.checkboxes.values()).some(s => s.isSaving)

    if (unsavedCount === 0 && !isAnyInFlight) {
      // Hide button, no unsaved changes
      this.saveAllButtonTarget.classList.add('hidden')
    } else {
      this.saveAllButtonTarget.classList.remove('hidden')
      
      if (isAnyInFlight) {
        this.saveAllButtonTarget.textContent = '💾 Saving...'
        this.saveAllButtonTarget.disabled = true
      } else if (unsavedCount > 0) {
        this.saveAllButtonTarget.textContent = `💾 Save All (${unsavedCount} unsaved)`
        this.saveAllButtonTarget.disabled = false
      }
    }
  }

  async saveAll() {
    console.debug(`🪲 MaterialSupplyRates: saveAll triggered, ${this.pendingSaves.size} unsaved changes`)
    
    const dirtyInputs = Array.from(this.pendingSaves).filter(el => el.classList.contains('rate-input'))
    const dirtyCheckboxes = Array.from(this.pendingSaves).filter(el => el.classList.contains('winner-checkbox'))

    this.updateSaveButton()

    // Save inputs sequentially, then checkboxes
    for (const input of dirtyInputs) {
      await this.saveRate(input)
    }

    for (const checkbox of dirtyCheckboxes) {
      await this.saveCheckbox(checkbox)
    }

    this.updateSaveButton()
    console.debug(`🪲 MaterialSupplyRates: saveAll complete`)
  }

  initSaveButton() {
    if (!this.hasSaveAllButtonTarget) {
      console.debug(`🪲 MaterialSupplyRates: Save All button target not found, skipping`)
      return
    }

    this.saveAllButtonTarget.addEventListener('click', () => this.saveAll())
    this.updateSaveButton()
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
