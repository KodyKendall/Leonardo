import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="menu"
export default class extends Controller {
  static targets = ["mobileMenu", "overlay", "panel"]

  toggle() {
    this.mobileMenuTarget.classList.toggle("hidden")
    
    this.overlayTarget.classList.toggle("opacity-0")
    this.overlayTarget.classList.toggle("opacity-100")

    this.panelTarget.classList.toggle("-translate-x-full")
    this.panelTarget.classList.toggle("translate-x-0")
  }
}