import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = {
    url: String
  }

  connect() {
    console.log("🪲 DEBUG: Sortable controller connected")
    console.log("🪲 DEBUG: Sortable URL:", this.urlValue)
    
    this.sortable = Sortable.create(this.element, {
      handle: ".drag-handle",
      draggable: "turbo-frame",
      animation: 150,
      ghostClass: "bg-blue-50",
      chosenClass: "shadow-lg",
      dragClass: "opacity-0",
      onEnd: this.onEnd.bind(this)
    })
  }

  onEnd(event) {
    const ids = this.sortable.toArray()
    console.log("🪲 DEBUG: Drag ended. New order IDs:", ids)
    
    if (!this.urlValue) {
      console.error("🪲 DEBUG: No URL provided for sorting")
      return
    }

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ ids: ids })
    }).then(response => {
      console.log("🪲 DEBUG: Reorder response status:", response.status)
      if (!response.ok) {
        console.error("🪲 DEBUG: Reorder failed")
      }
    }).catch(error => {
      console.error("🪲 DEBUG: Fetch error:", error)
    })
  }
}
