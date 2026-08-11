import { describe, it, expect } from 'vitest'
import {
  capPayload,
  MAX_PAGE_HTML_BYTES,
  MAX_SELECTED_ELEMENT_BYTES,
} from '../../../app/javascript/llamapress/payload_caps.js'

// SupportIncident #246. A page that inlines every meeting transcript rendered to
// 10.6 MB of markup, and that document was sent to the chat on EVERY message —
// as was the whole outerHTML (375 KB) of whatever the element picker was pointed
// at. LlamaBot caps both again on ingestion; this keeps them off the wire.
describe('capPayload', () => {
  const fatHtml = (bytes) =>
    '<html><body>' + '<div>transcript row</div>'.repeat(Math.ceil(bytes / 24)) + '</body></html>'

  it('leaves a normal page untouched', () => {
    const html = '<html><body><h1>Hello</h1></body></html>'
    expect(capPayload(html, MAX_PAGE_HTML_BYTES)).toBe(html)
  })

  it('caps a multi-megabyte page to the budget', () => {
    const capped = capPayload(fatHtml(10 * 1024 * 1024), MAX_PAGE_HTML_BYTES)
    expect(new TextEncoder().encode(capped).length).toBeLessThanOrEqual(MAX_PAGE_HTML_BYTES)
  })

  it('says how much it dropped, so the agent knows the document is partial', () => {
    const capped = capPayload(fatHtml(1024 * 1024), MAX_SELECTED_ELEMENT_BYTES)
    const marker = capped.match(/\[truncated: (\d+) bytes omitted\]/)
    expect(marker).not.toBeNull()
    expect(Number(marker[1])).toBeGreaterThan(0)
  })

  it('keeps the head and the tail, so the element is still identifiable', () => {
    const html = '<section id="transcripts">' + 'x'.repeat(500000) + '</section>'
    const capped = capPayload(html, MAX_SELECTED_ELEMENT_BYTES)
    expect(capped.startsWith('<section id="transcripts">')).toBe(true)
    expect(capped.endsWith('</section>')).toBe(true)
  })

  it('stays within budget for multi-byte content', () => {
    const capped = capPayload('日本語のテキスト'.repeat(100000), MAX_SELECTED_ELEMENT_BYTES)
    expect(new TextEncoder().encode(capped).length).toBeLessThanOrEqual(MAX_SELECTED_ELEMENT_BYTES)
  })

  it('never throws on a non-string', () => {
    expect(capPayload(null, MAX_PAGE_HTML_BYTES)).toBe(null)
    expect(capPayload(undefined, MAX_PAGE_HTML_BYTES)).toBe(undefined)
  })
})
