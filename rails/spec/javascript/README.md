# JavaScript/Stimulus Tests

This directory contains Vitest tests for Stimulus controllers and JavaScript behavior.

## Quick Start

```bash
# Run all JavaScript tests
docker compose exec llamapress npm test

# Watch mode (re-run on changes)
docker compose exec llamapress npm run test:watch

# Generate coverage report
docker compose exec llamapress npm run test:coverage
```

## Directory Structure

```
spec/javascript/
├── controllers/         # Stimulus controller tests
│   └── example_controller.test.js
├── helpers/            # Test utilities
│   └── rails_server.js # E2E helpers for testing with Rails
├── setup.js           # Global test configuration
└── README.md         # This file
```

## Writing Tests

### Basic Stimulus Controller Test

```javascript
import { describe, it, expect } from 'vitest'
import { Controller } from '@hotwired/stimulus'

describe('MyController', () => {
  it('should connect and work', async () => {
    class MyController extends Controller {
      connect() {
        this.element.textContent = 'Hello!'
      }
    }

    registerController('my', MyController)
    document.body.innerHTML = '<div data-controller="my"></div>'

    // Wait for Stimulus to connect
    await new Promise(resolve => setTimeout(resolve, 0))

    const element = document.querySelector('[data-controller="my"]')
    expect(element.textContent).toBe('Hello!')
  })
})
```

### Testing with Targets

```javascript
it('should access targets', async () => {
  class MyController extends Controller {
    static targets = ['output']

    greet() {
      this.outputTarget.textContent = 'Hello!'
    }
  }

  registerController('my', MyController)

  document.body.innerHTML = `
    <div data-controller="my">
      <button data-action="click->my#greet">Greet</button>
      <div data-my-target="output"></div>
    </div>
  `

  await new Promise(resolve => setTimeout(resolve, 0))

  document.querySelector('button').click()

  const output = document.querySelector('[data-my-target="output"]')
  expect(output.textContent).toBe('Hello!')
})
```

### Testing with Values

```javascript
it('should handle values', async () => {
  class MyController extends Controller {
    static values = { count: { type: Number, default: 0 } }

    increment() {
      this.countValue++
    }
  }

  registerController('my', MyController)

  document.body.innerHTML = `
    <div data-controller="my" data-my-count-value="5"></div>
  `

  await new Promise(resolve => setTimeout(resolve, 0))

  const element = document.querySelector('[data-controller="my"]')
  const controller = global.stimulusApp.getControllerForElementAndIdentifier(element, 'my')

  expect(controller.countValue).toBe(5)

  controller.increment()
  expect(controller.countValue).toBe(6)
})
```

## Global Test Helpers

Available in all tests via `spec/javascript/setup.js`:

### `registerController(name, controllerClass)`
Register a Stimulus controller for testing.

```javascript
registerController('hello', HelloController)
```

### `loadStimulus()`
Force Stimulus to scan and connect controllers.

```javascript
loadStimulus()
```

### `global.stimulusApp`
Access the Stimulus Application instance.

```javascript
const controller = global.stimulusApp.getControllerForElementAndIdentifier(element, 'hello')
```

## E2E Testing with Rails

Use the helpers in `spec/javascript/helpers/rails_server.js` to test against a live Rails server:

```javascript
import { fetchAndLoadHTML, fetchJSON } from '../../javascript/helpers/rails_server.js'

it('should load real Rails HTML', async () => {
  // Fetch HTML from running Rails server
  const container = await fetchAndLoadHTML('/users')

  // Stimulus controllers auto-connect to real HTML
  const elements = container.querySelectorAll('[data-controller]')
  expect(elements.length).toBeGreaterThan(0)

  // Test your controllers as they work in production
  // ...

  container.remove() // Cleanup
})
```

### Available E2E Helpers

- `fetchAndLoadHTML(path)` - Fetch and load Rails HTML into DOM
- `fetchJSON(path, options)` - Make JSON API requests
- `submitForm(formElement)` - Submit a form to Rails
- `waitForServer()` - Wait for Rails to be ready
- `RAILS_HOST` - Rails server URL (default: http://localhost:3000)

## Configuration

Tests are configured in:
- `vitest.config.js` (project root) - Main Vitest configuration
- `spec/javascript/setup.js` - Global setup and helpers
- `package.json` - NPM test scripts

## Environment

Tests use **happy-dom** for DOM simulation - a fast, lightweight alternative to jsdom. No browser needed!

## Coverage

Generate coverage reports:

```bash
docker compose exec llamapress npm run test:coverage
```

View: `coverage/index.html`

## Troubleshooting

### Controller not connecting?
Add a small delay after setting HTML:
```javascript
await new Promise(resolve => setTimeout(resolve, 0))
```

### Module not found?
Install dependencies:
```bash
docker compose exec llamapress npm install
```

### Global helper not defined?
Ensure you're importing from `vitest`:
```javascript
import { describe, it, expect } from 'vitest'
```

## Best Practices

1. **Always wait for connection** - Use `await new Promise(resolve => setTimeout(resolve, 0))` after setting HTML
2. **Clean tests** - Setup is automatic via `spec/javascript/setup.js`
3. **Use async/await** - Most Stimulus tests need async for connection
4. **Test behavior, not implementation** - Focus on what users see/do
5. **Keep tests isolated** - Each test gets fresh DOM and Stimulus app

## Examples

See `spec/javascript/controllers/example_controller.test.js` for comprehensive examples of:
- Controller mounting
- Target handling
- Value handling
- Action handling
- E2E patterns

## Learn More

- [Vitest Documentation](https://vitest.dev/)
- [Stimulus Handbook](https://stimulus.hotwired.dev/)
- [Testing Stimulus Controllers](https://stimulus.hotwired.dev/handbook/installing#testing)
