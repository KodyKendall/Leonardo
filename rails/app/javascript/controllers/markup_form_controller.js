import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  saveOnBlur(event) {
    const form = this.element
    
    fetch(form.action, {
      method: 'PATCH',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: new FormData(form)
    })
    .then(response => response.text())
    .then(html => {
      // Parse the response HTML which contains turbo-stream elements
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, 'text/html')
      
      // Find each turbo-stream element and apply it
      const streams = doc.querySelectorAll('turbo-stream')
      streams.forEach(stream => {
        // Use Turbo's built-in stream processing by cloning into document
        const clone = document.importNode(stream, true)
        // Append to body so Turbo processes it
        document.body.appendChild(clone)
        // Process happens asynchronously, remove after a tick
        requestAnimationFrame(() => clone.remove())
      })
    })
    .catch(error => console.error('Error:', error))
  }
}
