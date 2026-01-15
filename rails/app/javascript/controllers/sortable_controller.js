import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = {
    url: String,
    draggable: String
  }

  connect() {
    this.sortable = Sortable.create(this.element, {
      handle: ".drag-handle",
      draggable: this.draggableValue || "turbo-frame",
      animation: 150,
      ghostClass: "bg-blue-50",
      chosenClass: "shadow-lg",
      dragClass: "opacity-0",
      onEnd: this.onEnd.bind(this)
    })
  }

  onEnd(event) {
    const ids = this.sortable.toArray()
    
    if (!this.urlValue) {
      return
    }

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ ids: ids })
    })
  }
}
