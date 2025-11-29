import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "destroy"]
  
  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(
      /NEW_RECORD/g,
      new Date().getTime().toString()
    )
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }
  
  remove(event) {
    event.preventDefault()
    const wrapper = event.target.closest("[data-nested-form-wrapper]")
    const destroyInput = wrapper.querySelector("input[name*='_destroy']")
    const idInput = wrapper.querySelector("input[name*='[id]']")
    
    // If record is persisted (has ID), mark for destruction
    if (idInput && idInput.value) {
      destroyInput.value = "1"
      wrapper.style.display = "none"
    } else {
      // New record, just remove from DOM
      wrapper.remove()
    }
  }
}
