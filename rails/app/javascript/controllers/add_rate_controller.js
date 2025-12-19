import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("🪲 DEBUG: add_rate_controller connected")
  }

  submit(event) {
    console.log("🪲 DEBUG: Add Rate button clicked")
    console.log("🪲 DEBUG: Event:", event)
  }
}
