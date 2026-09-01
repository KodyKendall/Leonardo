import { describe, it, expect } from 'vitest'
import { isExecuteJsOriginAllowed, platformParentOrigin } from '../../../app/javascript/llamapress/execute_js_guard.js'

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

// The allowlist ships EMPTY on every box: LLAMABOT_ALLOWED_ORIGINS is declared in
// Leonardo/.env.example but never given a value, so window.LLAMABOT_ALLOWED_ORIGINS is []
// and this guard rejects everything. execute_browser_js has therefore been dead on all
// 148 boxes since it shipped — the origin guard landed without its producer ever being
// configured.
//
// The fix cannot be "default it to something permissive". It defaults to exactly ONE
// origin: the chat UI that serves this box, derived by inverting the rule the chat UI
// itself uses to build the iframe URL (`'https://rails-' + window.location.host`,
// chat/config.js:133). Nothing else is admitted, and an explicit allowlist still wins.
describe('platformParentOrigin', () => {
  it('strips the rails- prefix to find the chat UI that frames this page', () => {
    expect(platformParentOrigin('https://rails-leo-borro.llamapress.ai'))
      .toBe('https://leo-borro.llamapress.ai')
  })

  it('returns null for a host that is not a rails- subdomain', () => {
    // A custom customer domain is not the fleet topology, so nothing is derived and
    // the guard stays closed. Explicit configuration is the path for those boxes.
    expect(platformParentOrigin('https://app.customer.com')).toBeNull()
    expect(platformParentOrigin('http://localhost:3000')).toBeNull()
  })

  it('does not treat a look-alike host as a rails- subdomain', () => {
    expect(platformParentOrigin('https://railsfoo.llamapress.ai')).toBeNull()
    expect(platformParentOrigin('https://evil-rails-foo.llamapress.ai')).toBeNull()
  })

  it('preserves scheme and port rather than inventing them', () => {
    expect(platformParentOrigin('http://rails-box.example.com:3000'))
      .toBe('http://box.example.com:3000')
  })

  it('returns null for junk instead of throwing', () => {
    expect(platformParentOrigin('not-a-url')).toBeNull()
    expect(platformParentOrigin(undefined)).toBeNull()
  })
})

describe('isExecuteJsOriginAllowed — empty allowlist falls back to this box', () => {
  const PAGE = 'https://rails-leo-borro.llamapress.ai'
  const PARENT = 'https://leo-borro.llamapress.ai'

  it('admits the chat UI for this box when no allowlist is configured', () => {
    expect(isExecuteJsOriginAllowed(PARENT, [], PAGE)).toBe(true)
  })

  it('admits nothing else', () => {
    expect(isExecuteJsOriginAllowed('https://evil.com', [], PAGE)).toBe(false)
    // Another box's chat UI must not reach into this one.
    expect(isExecuteJsOriginAllowed('https://leo-other.llamapress.ai', [], PAGE)).toBe(false)
    // The page's own origin is not the parent.
    expect(isExecuteJsOriginAllowed(PAGE, [], PAGE)).toBe(false)
  })

  it('still fails closed on a box that is not a rails- subdomain', () => {
    expect(isExecuteJsOriginAllowed('https://anything.com', [], 'https://app.customer.com'))
      .toBe(false)
  })

  it('an explicit allowlist still wins and is still exact-match', () => {
    expect(isExecuteJsOriginAllowed('https://chosen.example.com',
      ['https://chosen.example.com'], PAGE)).toBe(true)
    // Configuring a list means the derived default is NOT also admitted — an operator
    // who narrows the list gets exactly what they asked for.
    expect(isExecuteJsOriginAllowed(PARENT, ['https://chosen.example.com'], PAGE)).toBe(false)
  })
})
