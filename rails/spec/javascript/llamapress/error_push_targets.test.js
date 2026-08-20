import { describe, it, expect } from 'vitest'
import { deriveChatOrigin, parentErrorTargets } from '../../../app/javascript/llamapress/error_push_targets.js'

// Where console_capture.js is allowed to push this page's JavaScript errors when
// it is framed by the LlamaBot chat. postMessage needs a concrete targetOrigin —
// '*' would hand error text (paths, record ids, anything caught in a stack) to
// whatever site framed the app — so this must never widen to a wildcard, and must
// never name an origin we did not either derive from our own host or have
// explicitly configured.
//
// Placeholder hosts only: the logic is origin-agnostic string work, and a real
// deployment URL in a spec rots.
describe('deriveChatOrigin', () => {
  it('strips the rails- host prefix (the deployed pairing)', () => {
    expect(deriveChatOrigin('https://rails-box.example.com')).toBe('https://box.example.com')
  })

  it('maps the dev Rails port to the dev chat port', () => {
    expect(deriveChatOrigin('http://localhost:3000')).toBe('http://localhost:8000')
  })

  it('preserves a non-default port when stripping the prefix', () => {
    expect(deriveChatOrigin('https://rails-box.example.com:9443')).toBe('https://box.example.com:9443')
  })

  it('derives nothing for a host with no known chat pairing', () => {
    expect(deriveChatOrigin('https://app.customer.example')).toBeNull()
  })

  it('returns null for junk instead of throwing (this runs inside a broken page)', () => {
    expect(deriveChatOrigin('')).toBeNull()
    expect(deriveChatOrigin(null)).toBeNull()
    expect(deriveChatOrigin(undefined)).toBeNull()
    expect(deriveChatOrigin('not a url')).toBeNull()
    expect(deriveChatOrigin(42)).toBeNull()
  })
})

describe('parentErrorTargets', () => {
  const RAILS = 'https://rails-box.example.com'

  it('includes the operator-configured allowlist', () => {
    expect(parentErrorTargets(RAILS, ['https://chat.example.com']))
      .toContain('https://chat.example.com')
  })

  it('still works when the allowlist is unset — the derived chat origin', () => {
    // The env var is unset on plenty of boxes; a debugging aid that silently does
    // nothing on most of the fleet is worse than no aid at all.
    expect(parentErrorTargets(RAILS, undefined)).toEqual(['https://box.example.com'])
    expect(parentErrorTargets(RAILS, [])).toEqual(['https://box.example.com'])
  })

  it('unions both sources without duplicating the derived origin', () => {
    const targets = parentErrorTargets(RAILS, ['https://box.example.com', 'https://chat.example.com'])
    expect(targets).toEqual(['https://box.example.com', 'https://chat.example.com'])
  })

  it('never emits a wildcard', () => {
    const targets = parentErrorTargets(RAILS, ['*'])
    expect(targets).toContain('*')  // an operator explicitly listing '*' is their call...
    expect(parentErrorTargets(RAILS, [])).not.toContain('*')  // ...but we never add one
  })

  it('drops our own origin — that is the un-framed case, not a parent', () => {
    expect(parentErrorTargets(RAILS, [RAILS])).not.toContain(RAILS)
  })

  it('trims whitespace from allowlist entries', () => {
    expect(parentErrorTargets(RAILS, ['  https://chat.example.com  ']))
      .toContain('https://chat.example.com')
  })

  it('ignores non-string allowlist entries and yields nothing derivable', () => {
    expect(parentErrorTargets('https://app.customer.example', [null, 42, {}, ''])).toEqual([])
  })
})
