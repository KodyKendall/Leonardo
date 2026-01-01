import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "viewDescription", "editDescription",
    "viewCategory", "editCategory",
    "viewQuantity", "editQuantity",
    "viewRate", "editRate",
    "viewTotal",
    "viewActions", "editActions",
    "viewTemplate", "editTemplate",
    "viewIsCrane", "editIsCrane",
    "viewIsAccessEquipment", "editIsAccessEquipment"
  ]

  static values = {
    trenderId: Number,
    itemId: Number
  }

  enterEditMode() {
    // Hide view mode, show edit mode
    this.viewActionsTarget.classList.add("hidden")
    this.editActionsTarget.classList.remove("hidden")

    // Hide all view fields, show edit fields
    this.viewDescriptionTarget.classList.add("hidden")
    this.editDescriptionTarget.classList.remove("hidden")

    this.viewCategoryTarget.classList.add("hidden")
    this.editCategoryTarget.classList.remove("hidden")

    this.viewQuantityTarget.classList.add("hidden")
    this.editQuantityTarget.classList.remove("hidden")

    this.viewRateTarget.classList.add("hidden")
    this.editRateTarget.classList.remove("hidden")

    if (this.hasEditTemplateTarget) this.editTemplateTarget.classList.remove("hidden")
    if (this.hasViewTemplateTarget) this.viewTemplateTarget.classList.add("hidden")

    if (this.hasEditIsCraneTarget) this.editIsCraneTarget.classList.remove("hidden")
    if (this.hasViewIsCraneTarget) this.viewIsCraneTarget.classList.add("hidden")

    if (this.hasEditIsAccessEquipmentTarget) this.editIsAccessEquipmentTarget.classList.remove("hidden")
    if (this.hasViewIsAccessEquipmentTarget) this.viewIsAccessEquipmentTarget.classList.add("hidden")

    // Focus on description field
    this.editDescriptionTarget.focus()
  }

  cancel() {
    // Reset edit fields to current values (in case user made changes)
    this.editDescriptionTarget.value = this.viewDescriptionTarget.textContent.trim()
    this.editQuantityTarget.value = this.viewQuantityTarget.textContent.trim().replace(/[^0-9.]/g, '')
    this.editRateTarget.value = this.viewRateTarget.textContent.trim().replace(/[^0-9.]/g, '')

    // Show view mode, hide edit mode
    this.viewActionsTarget.classList.remove("hidden")
    this.editActionsTarget.classList.add("hidden")

    // Show all view fields, hide edit fields
    this.viewDescriptionTarget.classList.remove("hidden")
    this.editDescriptionTarget.classList.add("hidden")

    this.viewCategoryTarget.classList.remove("hidden")
    this.editCategoryTarget.classList.add("hidden")

    this.viewQuantityTarget.classList.remove("hidden")
    this.editQuantityTarget.classList.add("hidden")

    this.viewRateTarget.classList.remove("hidden")
    this.editRateTarget.classList.add("hidden")

    if (this.hasEditTemplateTarget) this.editTemplateTarget.classList.add("hidden")
    if (this.hasViewTemplateTarget) this.viewTemplateTarget.classList.remove("hidden")

    if (this.hasEditIsCraneTarget) this.editIsCraneTarget.classList.add("hidden")
    if (this.hasViewIsCraneTarget) this.viewIsCraneTarget.classList.remove("hidden")

    if (this.hasEditIsAccessEquipmentTarget) this.editIsAccessEquipmentTarget.classList.add("hidden")
    if (this.hasViewIsAccessEquipmentTarget) this.viewIsAccessEquipmentTarget.classList.remove("hidden")
  }

  async applyTemplate(event) {
    const templateId = event.target.value
    if (!templateId) return

    try {
      const response = await fetch(`/p_and_g_templates/${templateId}.json`)
      if (response.ok) {
        const template = await response.json()
        
        // Update edit fields with template data
        this.editDescriptionTarget.value = template.description
        this.editCategoryTarget.value = template.category
        if (template.rate) this.editRateTarget.value = template.rate
        if (template.quantity) this.editQuantityTarget.value = template.quantity
        
        this.editIsCraneTarget.checked = template.is_crane
        this.editIsAccessEquipmentTarget.checked = template.is_access_equipment
      }
    } catch (error) {
      console.error("🪲 Error fetching template:", error)
    }
  }

  async save() {
    const itemId = this.element.dataset.itemId
    const tenderId = document.querySelector('[data-tender-id]')?.dataset.tenderId

    const data = {
      preliminaries_general_item: {
        description: this.editDescriptionTarget.value,
        category: this.editCategoryTarget.value,
        quantity: this.editQuantityTarget.value,
        rate: this.editRateTarget.value,
        is_crane: this.editIsCraneTarget.checked,
        is_access_equipment: this.editIsAccessEquipmentTarget.checked,
        preliminaries_general_item_template_id: this.editTemplateTarget.value || null
      }
    }

    try {
      const response = await fetch(
        `/tenders/${tenderId}/p_and_g/${itemId}`,
        {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            "Accept": "text/vnd.turbo-stream.html",
            "X-CSRF-Token": this.getCSRFToken()
          },
          body: JSON.stringify(data)
        }
      )

      if (response.ok) {
        // If the server returns a Turbo Stream, Turbo will handle it.
        // But since we're manually calling fetch, we might need to process it.
        // Actually, the simplest is to just request turbo_stream and let the controller handle it.
        const streamText = await response.text()
        Turbo.renderStreamMessage(streamText)
      } else {
        alert("Error saving item")
      }
    } catch (error) {
      console.error("Error:", error)
      alert("Error saving item")
    }
  }

  async delete() {
    if (!confirm("Are you sure you want to delete this item?")) {
      return
    }

    const itemId = this.element.dataset.itemId
    const tenderId = document.querySelector('[data-tender-id]')?.dataset.tenderId

    try {
      const response = await fetch(
        `/tenders/${tenderId}/p_and_g/${itemId}`,
        {
          method: "DELETE",
          headers: {
            "X-CSRF-Token": this.getCSRFToken()
          }
        }
      )

      if (response.ok) {
        // Remove the row from the table
        this.element.remove()

        // Update totals section
        this.updateTotals(tenderId)
      } else {
        alert("Error deleting item")
      }
    } catch (error) {
      console.error("Error:", error)
      alert("Error deleting item")
    }
  }

  async updateTotals(tenderId) {
    try {
      const response = await fetch(
        `/tenders/${tenderId}/p_and_g/totals`,
        {
          headers: { "Accept": "text/html" }
        }
      )

      if (response.ok) {
        const html = await response.text()
        const totalsElement = document.querySelector("#pg_totals")
        if (totalsElement) {
          // Replace the entire totals div with the new HTML
          totalsElement.outerHTML = html
        }
      }
    } catch (error) {
      console.error("🪲 Error updating totals:", error)
    }
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
