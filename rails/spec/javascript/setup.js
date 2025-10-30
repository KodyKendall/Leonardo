// Vitest setup file
import { Application, Controller } from '@hotwired/stimulus'
import { beforeEach, afterEach } from 'vitest'

// Make Stimulus available globally for tests
global.Application = Application
global.Controller = Controller

// Global test helpers
let application = null

beforeEach(() => {
  // Clean up document body
  document.body.innerHTML = ''

  // Create fresh Stimulus application for each test
  application = Application.start()
  global.stimulusApp = application
})

afterEach(() => {
  // Stop Stimulus application
  if (application) {
    application.stop()
    application = null
  }

  // Clean up DOM
  document.body.innerHTML = ''
})

// Helper to register a controller for testing
global.registerController = (name, controllerClass) => {
  if (!application) {
    throw new Error('Stimulus application not initialized. This should be called within a test.')
  }
  application.register(name, controllerClass)
}

// Helper to load/refresh Stimulus after DOM changes
global.loadStimulus = () => {
  if (!application) {
    throw new Error('Stimulus application not initialized.')
  }
  // Force Stimulus to scan for controllers
  application.load(application.schema.controllerAttribute)
}
