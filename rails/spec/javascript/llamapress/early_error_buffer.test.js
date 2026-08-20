import { describe, it, expect } from 'vitest'
import { drainEarlyErrors } from '../../../app/javascript/llamapress/early_error_buffer.js'

// console_capture.js is a deferred ES module, so an inline <script> that throws
// while the body is parsing does so BEFORE console_capture's error listener
// exists. That is exactly the "I loaded the page and it's broken" error a user
// most wants to report, and it used to be recorded nowhere. A classic inline
// script in the layout head buffers those; this drains the buffer.
describe('drainEarlyErrors', () => {
  it('normalises an uncaught error, folding file and line into the message', () => {
    const win = {
      __llamapressEarlyErrors: [
        { kind: 'uncaught', message: 'Uncaught ReferenceError: boom is not defined',
          filename: 'http://x/page', lineno: 461, stack: 'ReferenceError: boom\n  at page:461' },
      ],
    }
    expect(drainEarlyErrors(win)).toEqual([
      {
        kind: 'uncaught',
        message: 'Uncaught ReferenceError: boom is not defined at http://x/page:461',
        stack: 'ReferenceError: boom\n  at page:461',
      },
    ])
  })

  it('normalises an unhandled rejection (no file/line to fold in)', () => {
    const win = {
      __llamapressEarlyErrors: [{ kind: 'unhandled-rejection', message: 'fetch failed', stack: 'Error: fetch failed' }],
    }
    expect(drainEarlyErrors(win)).toEqual([
      { kind: 'unhandled-rejection', message: 'fetch failed', stack: 'Error: fetch failed' },
    ])
  })

  it('preserves order — the first thing that broke reads first', () => {
    const win = {
      __llamapressEarlyErrors: [
        { kind: 'uncaught', message: 'first' },
        { kind: 'uncaught', message: 'second' },
      ],
    }
    expect(drainEarlyErrors(win).map((e) => e.message)).toEqual(['first', 'second'])
  })

  it('nulls the buffer so the early listeners stand down', () => {
    // Null is the handshake: the inline script checks for it and stops recording
    // once console_capture owns the listeners. Deleting the key would not work.
    const win = { __llamapressEarlyErrors: [{ kind: 'uncaught', message: 'boom' }] }
    drainEarlyErrors(win)
    expect(win.__llamapressEarlyErrors).toBeNull()
  })

  it('drains only once — a second call yields nothing', () => {
    const win = { __llamapressEarlyErrors: [{ kind: 'uncaught', message: 'boom' }] }
    expect(drainEarlyErrors(win)).toHaveLength(1)
    expect(drainEarlyErrors(win)).toEqual([])
  })

  it('returns nothing when no early error happened', () => {
    expect(drainEarlyErrors({ __llamapressEarlyErrors: [] })).toEqual([])
    expect(drainEarlyErrors({})).toEqual([])
  })

  it('survives junk instead of throwing (it runs inside a broken page)', () => {
    expect(drainEarlyErrors(null)).toEqual([])
    expect(drainEarlyErrors(undefined)).toEqual([])
    expect(drainEarlyErrors({ __llamapressEarlyErrors: 'not an array' })).toEqual([])
    expect(drainEarlyErrors({ __llamapressEarlyErrors: [null, undefined, {}, { message: '' }] })).toEqual([])
  })

  it('caps a hostile stack instead of shipping unbounded text', () => {
    const win = { __llamapressEarlyErrors: [{ kind: 'uncaught', message: 'boom', stack: 'x'.repeat(10000) }] }
    expect(drainEarlyErrors(win)[0].stack).toHaveLength(4000)
  })

  it('drops a non-string stack rather than passing it through', () => {
    const win = { __llamapressEarlyErrors: [{ kind: 'uncaught', message: 'boom', stack: { evil: true } }] }
    expect(drainEarlyErrors(win)[0].stack).toBeNull()
  })
})
