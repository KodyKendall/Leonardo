import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["materialSelect", "rateInput", "wastePercentageInput"]

  connect() {
    // Controller is connected and ready
  }

  async autoFill(event) {
    const materialSelectElement = event.target
    const materialSupplyId = materialSelectElement.value

    // Do nothing if no material is selected
    if (!materialSupplyId) {
      return
    }

    // Extract tender ID from data attribute
    const tenderId = this.element.dataset.tenderId
    const materialSupplyType = this.element.dataset.materialSupplyType

    if (!tenderId) {
      return
    }

    try {
      // Fetch autofill data from server
      const response = await fetch(
        `/tenders/${tenderId}/material_autofill?material_supply_id=${materialSupplyId}&material_supply_type=${materialSupplyType}`,
        {
          headers: {
            "Accept": "application/json"
          }
        }
      )

      if (!response.ok) {
        return
      }

      const data = await response.json()

      // Populate rate field if autofill data contains a rate
      if (this.hasRateInputTarget && data.rate !== null && data.rate !== undefined) {
        this.rateInputTarget.value = data.rate
      }

      // Populate waste percentage field if autofill data contains waste_percentage
      if (this.hasWastePercentageInputTarget && data.waste_percentage !== null && data.waste_percentage !== undefined) {
        this.wastePercentageInputTarget.value = data.waste_percentage
      }

      // Trigger change events on inputs so dirty-form controller detects changes
      if (this.hasRateInputTarget) {
        this.rateInputTarget.dispatchEvent(new Event("change", { bubbles: true }))
      }
      if (this.hasWastePercentageInputTarget) {
        this.wastePercentageInputTarget.dispatchEvent(new Event("change", { bubbles: true }))
      }

    } catch (error) {
      // Silently fail if fetch encounters an error
    }
  }
}
