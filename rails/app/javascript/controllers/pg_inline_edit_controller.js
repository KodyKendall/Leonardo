import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "viewDescription", "editDescription",
    "viewCategory", "editCategory",
    "viewQuantity", "editQuantity",
    "viewRate", "editRate",
    "viewTotal",
    "viewActions", "editActions"
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

    // Focus on description field
    this.editDescriptionTarget.focus()
  }

  cancel() {
    // Reset edit fields to current values (in case user made changes)
    this.editDescriptionTarget.value = this.viewDescriptionTarget.textContent.trim()
    this.editQuantityTarget.value = this.viewQuantityTarget.textContent.trim()
    this.editRateTarget.value = this.viewRateTarget.textContent.trim()

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
  }

  async save() {
    const itemId = this.element.dataset.itemId
    const tenderId = document.querySelector('[data-tender-id]')?.dataset.tenderId

    const data = {
      preliminaries_general_item: {
        description: this.editDescriptionTarget.value,
        category: this.editCategoryTarget.value,
        quantity: this.editQuantityTarget.value,
        rate: this.editRateTarget.value
      }
    }

    try {
      const response = await fetch(
        `/tenders/${tenderId}/p_and_g/${itemId}`,
        {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": this.getCSRFToken()
          },
          body: JSON.stringify(data)
        }
      )

      if (response.ok) {
        const result = await response.json()

        // Update display values
        this.viewDescriptionTarget.textContent = result.description
        this.viewCategoryTarget.textContent = result.category_display
        this.viewQuantityTarget.textContent = result.quantity_display
        this.viewRateTarget.textContent = result.rate_display
        this.viewTotalTarget.textContent = result.total_display

        // Exit edit mode
        this.cancel()

        // Update totals section
        this.updateTotals(tenderId)
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
