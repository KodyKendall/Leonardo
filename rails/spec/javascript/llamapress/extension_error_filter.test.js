import { describe, it, expect } from 'vitest'
import { isExtensionOnly } from '../../../app/javascript/llamapress/extension_error_filter.js'

// Browser extensions (MetaMask, password managers, request interceptors) inject
// scripts into the MAIN WORLD of every document they can reach, including the
// Rails app inside the preview iframe. Their scripts share `window` with the
// app, so when they throw, the app's own listeners in console_capture.js fire
// and the error is pushed to the chat as if the app had produced it. Leo then
// spends a paragraph reassuring the user about MetaMask.
//
// Origin checks cannot help — the frame really is the app's origin. The only
// provenance signal is the URL scheme in the stack frames, which is what this
// module reads.
//
// The subtlety, and the reason this is not "contains chrome-extension://": an
// extension that monkey-patches window.fetch sits on TOP of a stack whose lower
// frames are the app's own code, and that error IS the app's problem. Drop an
// error only when nothing in it comes from an http(s) origin.
describe('isExtensionOnly', () => {
  it('drops a MetaMask rejection thrown entirely inside the extension', () => {
    expect(isExtensionOnly({
      message: 'Failed to connect to MetaMask',
      stack: [
        'i: Failed to connect to MetaMask',
        '    at Object.connect (chrome-extension://nkbihfbeogaeaoehlefnkodbefgpgknn/scripts/inpage.js:7:84292)'
      ].join('\n')
    })).toBe(true)
  })

  it('KEEPS an extension frame sitting on top of the app\'s own frames', () => {
    // A request-interceptor extension patched window.fetch, so it is the top
    // frame — but "Failed to fetch" was a real problem in the app's Turbo.
    expect(isExtensionOnly({
      message: 'TypeError: Failed to fetch',
      stack: [
        'TypeError: Failed to fetch',
        '    at s.fetch (chrome-extension://eppiocemhmnlbhjplcgkofciiegomcon/libs/requests.js:1:3633)',
        '    at $ (https://rails-leo-mevve.leo.llamapress.ai/assets/turbo.min-38d0308.js:5:8309)',
        '    at X.perform (https://rails-leo-mevve.leo.llamapress.ai/assets/turbo.min-38d0308.js:5:10084)'
      ].join('\n')
    })).toBe(false)
  })

  it('keeps a bare "Script error." — that is a CORS rule, not an extension', () => {
    expect(isExtensionOnly({ message: 'Script error. at :0' })).toBe(false)
  })

  it('keeps an ordinary app error with no extension frame anywhere', () => {
    expect(isExtensionOnly({
      message: "TypeError: Cannot read properties of null (reading 'value')",
      stack: [
        "TypeError: Cannot read properties of null (reading 'value')",
        '    at submit (https://rails-box.example.com/assets/application.js:12:44)'
      ].join('\n')
    })).toBe(false)
  })

  it('drops a Firefox uncaught error located only by filename', () => {
    expect(isExtensionOnly({
      message: 'ReferenceError: wallet is not defined',
      filename: 'moz-extension://8f0c1c2e-0000-4000-8000-abcdef012345/content.js'
    })).toBe(true)
  })

  it('matches the other extension schemes we have seen', () => {
    for (const url of [
      'safari-web-extension://ABCD-1234/inject.js',
      'safari-extension://com.example.ext/inject.js',
      'ms-browser-extension://abcdefg/inject.js'
    ]) {
      expect(isExtensionOnly({ message: 'boom', stack: `boom\n    at x (${url}:1:1)` })).toBe(true)
    }
  })

  it('does not throw on junk — this runs inside an already broken page', () => {
    expect(isExtensionOnly()).toBe(false)
    expect(isExtensionOnly({})).toBe(false)
    expect(isExtensionOnly({ message: null, stack: undefined })).toBe(false)
  })
})
