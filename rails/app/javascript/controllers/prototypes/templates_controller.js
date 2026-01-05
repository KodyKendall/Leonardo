import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["materialsTable"]

  connect() {
    console.log("Section Category Templates prototype connected")
  }

  showNewTemplateModal() {
    document.getElementById('new-template-modal').checked = true
  }

  bulkCreate() {
    const materials = [
      { name: "Aggregate 20mm", proportion: 40, waste: 3 },
      { name: "River Sand", proportion: 30, waste: 5 },
      { name: "Portland Cement", proportion: 20, waste: 2 },
      { name: "Water", proportion: 10, waste: 0 }
    ]

    materials.forEach(m => {
      this.addMaterialRow(m.name, m.proportion, m.waste)
    })
  }

  addMaterialRow(name, proportion, waste) {
    const row = document.createElement("tr")
    row.innerHTML = `
      <td>
        <select class="select select-bordered select-sm w-full">
          <option selected>${name}</option>
          <option>Cement Type GP</option>
          <option>Fine Sand</option>
          <option>10mm Blue Metal</option>
          <option>Water</option>
          <option>Fly Ash</option>
        </select>
      </td>
      <td><input type="number" value="${proportion}" class="input input-bordered input-sm w-full" /></td>
      <td><input type="number" value="${waste}" class="input input-bordered input-sm w-full" /></td>
      <td>
        <button class="btn btn-ghost btn-xs text-error" onclick="this.closest('tr').remove()">
          <i class="fas fa-trash"></i>
        </button>
      </td>
    `
    this.materialsTableTarget.appendChild(row)
  }

  selectTemplate(event) {
    // Just a visual cue for the prototype
    const rows = event.currentTarget.closest('tbody').querySelectorAll('tr')
    rows.forEach(r => r.classList.remove('bg-base-200'))
    event.currentTarget.closest('tr').classList.add('bg-base-200')
  }
}
