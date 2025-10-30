// Helper for testing against Rails server without a browser
// This allows E2E testing of Stimulus controllers by fetching real HTML from Rails

const RAILS_HOST = process.env.RAILS_TEST_HOST || 'http://localhost:3000'

/**
 * Fetch HTML from Rails server and load it into the DOM
 * @param {string} path - The path to fetch (e.g., '/users')
 * @param {Object} options - Fetch options
 * @returns {Promise<HTMLElement>} The container with loaded HTML
 */
export async function fetchAndLoadHTML(path, options = {}) {
  const response = await fetch(`${RAILS_HOST}${path}`, {
    ...options,
    headers: {
      'Accept': 'text/html',
      ...options.headers
    }
  })

  if (!response.ok) {
    throw new Error(`Failed to fetch ${path}: ${response.status} ${response.statusText}`)
  }

  const html = await response.text()

  // Create container and load HTML
  const container = document.createElement('div')
  container.innerHTML = html
  document.body.appendChild(container)

  return container
}

/**
 * Make a JSON API request to Rails
 * @param {string} path - The path to fetch
 * @param {Object} options - Fetch options
 * @returns {Promise<Object>} The JSON response
 */
export async function fetchJSON(path, options = {}) {
  const response = await fetch(`${RAILS_HOST}${path}`, {
    ...options,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...options.headers
    }
  })

  if (!response.ok) {
    throw new Error(`Failed to fetch ${path}: ${response.status} ${response.statusText}`)
  }

  return response.json()
}

/**
 * Submit a form to Rails
 * @param {HTMLFormElement} form - The form element to submit
 * @returns {Promise<Response>} The response
 */
export async function submitForm(form) {
  const formData = new FormData(form)
  const method = form.method || 'POST'
  const action = form.action || window.location.href

  return fetch(action, {
    method: method.toUpperCase(),
    body: formData,
    headers: {
      'X-Requested-With': 'XMLHttpRequest'
    }
  })
}

/**
 * Wait for Rails server to be ready
 * @param {number} maxAttempts - Maximum number of connection attempts
 * @param {number} delay - Delay between attempts in ms
 * @returns {Promise<boolean>}
 */
export async function waitForServer(maxAttempts = 30, delay = 1000) {
  for (let i = 0; i < maxAttempts; i++) {
    try {
      const response = await fetch(`${RAILS_HOST}/up`, {
        method: 'GET',
        signal: AbortSignal.timeout(5000)
      })
      if (response.ok) {
        return true
      }
    } catch (error) {
      // Server not ready, wait and retry
      if (i < maxAttempts - 1) {
        await new Promise(resolve => setTimeout(resolve, delay))
      }
    }
  }
  throw new Error(`Rails server not ready after ${maxAttempts} attempts`)
}

export { RAILS_HOST }
