import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["materialSelect", "supplierSelect", "rateInput"]
  static values = {
    url: String,
    monthlyRateId: String
  }

  async updateRate() {
    const materialId = this.materialSelectTarget.value
    const supplierId = this.supplierSelectTarget.value
    const monthlyRateId = this.monthlyRateIdValue

    console.log("🪲 DEBUG: updateRate called", { materialId, supplierId, monthlyRateId })

    if (!materialId || !supplierId || !monthlyRateId) {
      // Clear the rate if supplier is missing as per requirements
      if (!supplierId) {
        this.rateInputTarget.value = ""
        this.rateInputTarget.dispatchEvent(new Event("input", { bubbles: true }))
        this.rateInputTarget.dispatchEvent(new Event("change", { bubbles: true }))
      }
      return
    }

    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.append("material_supply_id", materialId)
      url.searchParams.append("supplier_id", supplierId)
      url.searchParams.append("monthly_rate_id", monthlyRateId)

      const response = await fetch(url, {
        headers: {
          "Accept": "application/json"
        }
      })

      if (response.ok) {
        const data = await response.json()
        console.log("🪲 DEBUG: rate lookup response", data)
        if (data.rate !== null && data.rate !== undefined) {
          this.rateInputTarget.value = data.rate
          // Trigger events so other controllers (like dirty-form) notice the change
          this.rateInputTarget.dispatchEvent(new Event("input", { bubbles: true }))
          this.rateInputTarget.dispatchEvent(new Event("change", { bubbles: true }))
        }
      }
    } catch (error) {
      console.error("🪲 DEBUG: Error fetching material rate:", error)
    }
  }
}
