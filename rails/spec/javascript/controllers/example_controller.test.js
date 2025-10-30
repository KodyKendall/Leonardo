import { describe, it, expect } from 'vitest'
import { Controller } from '@hotwired/stimulus'

// Example tests for Stimulus controllers
// This demonstrates both unit testing and E2E patterns

describe('Stimulus Controller - Unit Tests', () => {
  it('should mount and connect a controller', async () => {
    // Define a simple controller
    class HelloController extends Controller {
      connect() {
        this.element.textContent = 'Hello, Stimulus!'
      }
    }

    // Register the controller using global helper
    registerController('hello', HelloController)

    // Add HTML with controller
    document.body.innerHTML = '<div data-controller="hello"></div>'

    // Wait for next tick to allow Stimulus to connect
    await new Promise(resolve => setTimeout(resolve, 0))

    // Assert controller connected and ran
    const element = document.querySelector('[data-controller="hello"]')
    expect(element.textContent).toBe('Hello, Stimulus!')
  })

  it('should handle controller targets', async () => {
    class GreeterController extends Controller {
      static targets = ['name', 'output']

      greet() {
        const name = this.nameTarget.value
        this.outputTarget.textContent = `Hello, ${name}!`
      }
    }

    registerController('greeter', GreeterController)

    document.body.innerHTML = `
      <div data-controller="greeter">
        <input data-greeter-target="name" value="World" />
        <button data-action="click->greeter#greet">Greet</button>
        <div data-greeter-target="output"></div>
      </div>
    `

    // Wait for Stimulus to connect
    await new Promise(resolve => setTimeout(resolve, 0))

    const button = document.querySelector('button')
    button.click()

    const output = document.querySelector('[data-greeter-target="output"]')
    expect(output.textContent).toBe('Hello, World!')
  })

  it('should handle controller values', async () => {
    class CounterController extends Controller {
      static values = { count: { type: Number, default: 0 } }

      increment() {
        this.countValue++
        this.element.textContent = this.countValue
      }
    }

    registerController('counter', CounterController)

    document.body.innerHTML = `
      <div data-controller="counter" data-counter-count-value="5"></div>
    `

    // Wait for Stimulus to connect
    await new Promise(resolve => setTimeout(resolve, 0))

    const element = document.querySelector('[data-controller="counter"]')
    const controller = global.stimulusApp.getControllerForElementAndIdentifier(element, 'counter')

    expect(controller.countValue).toBe(5)

    controller.increment()
    expect(controller.countValue).toBe(6)
    expect(element.textContent).toBe('6')
  })
})

// E2E Testing Pattern (requires Rails server to be running)
// Uncomment this section when you want to test against a live Rails server
/*
import { fetchAndLoadHTML, RAILS_HOST } from '../../javascript/helpers/rails_server.js'

describe.skip('Stimulus Controller - E2E Tests', () => {
  it('should load real HTML from Rails and test controller', async () => {
    // Fetch actual HTML from your Rails app
    const container = await fetchAndLoadHTML('/users')

    // Your Stimulus controllers should auto-connect to the loaded HTML
    // Test them as they would work in production
    const userElements = container.querySelectorAll('[data-controller]')
    expect(userElements.length).toBeGreaterThan(0)

    // Clean up
    container.remove()
  })
})
*/
