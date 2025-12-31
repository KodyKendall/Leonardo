import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async quickAdd() {
    const tenderId = document.querySelector('[data-tender-id]')?.dataset.tenderId

    try {
      const response = await fetch(
        `/tenders/${tenderId}/p_and_g`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": this.getCSRFToken()
          },
          body: JSON.stringify({
            preliminaries_general_item: {
              description: "New P&G Item",
              category: "fixed_based",
              quantity: 1,
              rate: 0
            }
          })
        }
      )

      if (response.ok) {
        const result = await response.json()

        // Create the new row HTML
        const row = document.createElement('tr')
        row.id = result.dom_id
        row.classList.add('hover:bg-gray-50', 'border-b', 'border-gray-200', 'group')
        row.dataset.controller = 'pg-inline-edit'
        row.dataset.itemId = result.id

        row.innerHTML = `
          <!-- Description -->
          <td class="px-6 py-4 text-sm text-gray-900 font-medium">
            <span data-pg-inline-edit-target="viewDescription" class="cursor-pointer inline-block">${result.description}</span>
            <input type="text" data-pg-inline-edit-target="editDescription" class="input input-bordered input-sm w-full hidden" value="${result.description}">
          </td>
          
          <!-- Category -->
          <td class="px-6 py-4 text-sm text-gray-500 w-40">
            <span data-pg-inline-edit-target="viewCategory" class="cursor-pointer inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
              ${result.category_display}
            </span>
            <select data-pg-inline-edit-target="editCategory" class="select select-bordered select-sm w-full hidden">
              <option value="fixed_based" ${result.category === 'fixed_based' ? 'selected' : ''}>Fixed Based</option>
              <option value="duration_based" ${result.category === 'duration_based' ? 'selected' : ''}>Duration Based</option>
              <option value="percentage_based" ${result.category === 'percentage_based' ? 'selected' : ''}>Percentage Based</option>
            </select>
          </td>
          
          <!-- Quantity -->
          <td class="px-6 py-4 text-sm text-gray-600 text-right w-32">
            <span data-pg-inline-edit-target="viewQuantity" class="cursor-pointer inline-block">${result.quantity_display}</span>
            <input type="number" step="0.001" data-pg-inline-edit-target="editQuantity" class="input input-bordered input-sm w-full text-right hidden" value="${result.quantity}">
          </td>
          
          <!-- Rate -->
          <td class="px-6 py-4 text-sm text-gray-600 text-right w-32">
            <span data-pg-inline-edit-target="viewRate" class="cursor-pointer inline-block">${result.rate_display}</span>
            <input type="number" step="0.01" data-pg-inline-edit-target="editRate" class="input input-bordered input-sm w-full text-right hidden" value="${result.rate}">
          </td>
          
          <!-- Total -->
          <td class="px-6 py-4 text-sm font-semibold text-gray-900 text-right w-32">
            <span data-pg-inline-edit-target="viewTotal">${result.total_display}</span>
          </td>
          
          <!-- Actions -->
          <td class="px-6 py-4 text-right text-sm font-medium w-24">
            <div class="flex justify-end gap-3">
              <!-- Edit Mode Button (hidden by default) -->
              <div data-pg-inline-edit-target="editActions" class="flex gap-2 hidden">
                <button data-action="pg-inline-edit#save" class="text-green-600 hover:text-green-900" title="Save">
                  <i class="fa-solid fa-check"></i>
                </button>
                <button data-action="pg-inline-edit#cancel" class="text-gray-400 hover:text-gray-600" title="Cancel">
                  <i class="fa-solid fa-xmark"></i>
                </button>
              </div>
              
              <!-- View Mode Buttons -->
              <div data-pg-inline-edit-target="viewActions" class="flex gap-3">
                <button data-action="pg-inline-edit#enterEditMode" class="text-indigo-600 hover:text-indigo-900 opacity-0 group-hover:opacity-100 transition-opacity" title="Edit">
                  <i class="fa-solid fa-pencil"></i>
                </button>
                <button data-action="pg-inline-edit#delete" class="text-red-600 hover:text-red-900 opacity-0 group-hover:opacity-100 transition-opacity" title="Delete">
                  <i class="fa-solid fa-trash"></i>
                </button>
              </div>
            </div>
          </td>
        `

        // Add row to table
        const tableBody = document.querySelector('#pg_items_table_body')
        tableBody.appendChild(row)

        // Re-initialize the Stimulus controller for this new row
        window.Stimulus?.application?.register('pg-inline-edit', () => {
          return import('../controllers/pg_inline_edit_controller').then(m => m.default)
        })

        // Update totals
        this.updateTotals(tenderId)
      } else {
        alert("Error creating item")
      }
    } catch (error) {
      console.error("Error:", error)
      alert("Error creating item")
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
