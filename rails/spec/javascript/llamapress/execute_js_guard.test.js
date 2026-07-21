import { describe, it, expect } from 'vitest'
import { isExecuteJsOriginAllowed } from '../../../app/javascript/llamapress/execute_js_guard.js'

// Security guard for the execute-js postMessage command (execute_browser_js tool).
// Arbitrary JS may run ONLY when the sender's origin is in the configured allowlist,
// and MUST fail closed when the allowlist is missing/empty — otherwise any site that
// frames the app could run code in a logged-in user's session.
describe('isExecuteJsOriginAllowed', () => {
  // Placeholder origins — the guard is origin-agnostic string logic, so tests must
  // not depend on any real deployment URL. A LlamaBot instance's actual origin comes
  // from the LLAMABOT_ALLOWED_ORIGINS env var at runtime, never from this code.
  const ALLOWED = 'https://llamabot.example.com'

  it('allows a configured LlamaBot origin', () => {
    expect(isExecuteJsOriginAllowed(ALLOWED, [ALLOWED])).toBe(true)
  })

  it('allows any origin present in a multi-entry allowlist', () => {
    const list = ['https://a.example.com', ALLOWED, 'https://b.example.com']
    expect(isExecuteJsOriginAllowed(ALLOWED, list)).toBe(true)
  })

  it('rejects an origin not in the allowlist (malicious framing site)', () => {
    expect(isExecuteJsOriginAllowed('https://evil.example.com', [ALLOWED])).toBe(false)
  })

  it('fails closed on an empty allowlist (env var unset)', () => {
    expect(isExecuteJsOriginAllowed(ALLOWED, [])).toBe(false)
  })

  it('fails closed when the allowlist is undefined (global never injected)', () => {
    expect(isExecuteJsOriginAllowed(ALLOWED, undefined)).toBe(false)
  })

  it('fails closed when the allowlist is not an array', () => {
    expect(isExecuteJsOriginAllowed(ALLOWED, ALLOWED)).toBe(false)
  })

  it('is exact-match: a look-alike host / different scheme / different port does not pass', () => {
    expect(isExecuteJsOriginAllowed('https://llamabot.example.com.evil.com', [ALLOWED])).toBe(false)
    expect(isExecuteJsOriginAllowed('http://llamabot.example.com', [ALLOWED])).toBe(false)
    expect(isExecuteJsOriginAllowed('https://llamabot.example.com:8443', [ALLOWED])).toBe(false)
  })

  it('rejects the wildcard string (must be a real origin, not "*")', () => {
    expect(isExecuteJsOriginAllowed('*', [ALLOWED])).toBe(false)
  })
})
