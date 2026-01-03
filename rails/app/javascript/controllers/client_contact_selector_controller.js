import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["clientSelect", "contactSelect"]

  connect() {
    // Initialize contact dropdown based on currently selected client
    this.updateContacts()
  }

  updateContacts() {
    const clientId = this.clientSelectTarget.value

    if (!clientId) {
      // No client selected: disable and clear contact dropdown
      this.contactSelectTarget.disabled = true
      this.contactSelectTarget.innerHTML = '<option value="">-- Select a client first --</option>'
      return
    }

    // Fetch contacts for the selected client
    fetch(`/clients/${clientId}/contacts`, {
      headers: {
        "Accept": "application/json"
      }
    })
      .then(response => {
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`)
        return response.json()
      })
      .then(contacts => {
        this.populateContactDropdown(contacts)
      })
      .catch(error => {
        console.error("Error fetching contacts:", error)
        this.contactSelectTarget.innerHTML = '<option value="">Error loading contacts</option>'
        this.contactSelectTarget.disabled = true
      })
  }

  populateContactDropdown(contacts) {
    const select = this.contactSelectTarget
    let primaryContactId = null

    // Build options
    const options = ['<option value="">-- Select a contact --</option>']
    
    contacts.forEach(contact => {
      const selected = contact.is_primary ? ' selected' : ''
      if (contact.is_primary) {
        primaryContactId = contact.id
      }
      
      // Display contact name and email (if available)
      const displayText = contact.email 
        ? `${contact.name} (${contact.email})`
        : contact.name
      
      options.push(`<option value="${contact.id}"${selected}>${displayText}</option>`)
    })

    select.innerHTML = options.join('')
    select.disabled = false
  }
}
