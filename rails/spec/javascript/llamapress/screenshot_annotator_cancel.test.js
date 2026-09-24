import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

// Cancelling a feedback screenshot left the user on a blank page with the
// feedback panel gone (SI#479's second defect, fixed on the customer boxes but
// never upstream).
//
// Cause: the feedback bubble hides its panel before calling startCapture(cb)
// and only reopens it from inside cb. Every way OUT of a capture that wasn't a
// successful attach — Cancel on the drag overlay, Cancel/× on the annotation
// modal, a failed capture, a failed attach — restored the floating bubble but
// never called cb. The panel (and the draft typed in it) stayed hidden.
//
// The fix: every exit consumes the callback exactly once. A successful attach
// passes the attachment; every other exit passes null, which the bubble reads
// as "reopen, nothing to add".

const MODULE = '../../../app/javascript/llamapress/screenshot_annotator.js'

let annotator
let onAttach

beforeEach(async () => {
  vi.resetModules()
  delete window.screenshotAnnotator
  document.body.innerHTML = '<div id="llamapress-feedback-bubble"></div>'
  // Present already, so ensureDependencies() injects no script tags.
  window.html2canvas = vi.fn()
  window.fabric = {}
  await import(MODULE)
  annotator = window.screenshotAnnotator
  onAttach = vi.fn()
})

afterEach(() => {
  vi.restoreAllMocks()
  delete window.screenshotAnnotator
  delete window.html2canvas
  delete window.fabric
  document.body.innerHTML = ''
})

const bubble = () => document.getElementById('llamapress-feedback-bubble')

describe('leaving a screenshot capture without attaching', () => {
  it('Cancel on the drag overlay hands control back to the feedback panel', async () => {
    await annotator.startCapture(onAttach)
    expect(bubble().style.display).toBe('none')

    const cancel = document.getElementById('screenshot-cancel')
    cancel.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }))

    expect(document.getElementById('screenshot-selection-overlay')).toBeNull()
    expect(bubble().style.display).toBe('')
    expect(onAttach).toHaveBeenCalledTimes(1)
    expect(onAttach).toHaveBeenCalledWith(null)
  })

  it('closing the annotation modal hands control back to the feedback panel', async () => {
    annotator.onAttachCallback = onAttach
    annotator.modal = document.createElement('div')
    document.body.appendChild(annotator.modal)

    annotator.closeModal()

    expect(annotator.modal).toBeNull()
    expect(onAttach).toHaveBeenCalledTimes(1)
    expect(onAttach).toHaveBeenCalledWith(null)
  })

  it('a failed capture hands control back to the feedback panel', async () => {
    await annotator.startCapture(onAttach)
    vi.spyOn(annotator, 'captureRegion').mockRejectedValue(new Error('denied'))
    vi.spyOn(console, 'error').mockImplementation(() => {})
    const overlay = document.getElementById('screenshot-selection-overlay')

    overlay.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, clientX: 10, clientY: 10 }))
    overlay.dispatchEvent(new MouseEvent('mousemove', { bubbles: true, clientX: 200, clientY: 200 }))
    // happy-dom does no layout; give the drawn box the size it would have.
    vi.spyOn(HTMLElement.prototype, 'getBoundingClientRect')
      .mockReturnValue({ left: 10, top: 10, width: 190, height: 190 })
    overlay.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, clientX: 200, clientY: 200 }))
    await vi.waitFor(() => expect(onAttach).toHaveBeenCalled())

    expect(onAttach).toHaveBeenCalledTimes(1)
    expect(onAttach).toHaveBeenCalledWith(null)
    expect(bubble().style.display).toBe('')
  })

  it('a successful attach calls back once, with the attachment — not again with null', async () => {
    annotator.onAttachCallback = onAttach
    annotator.modal = document.createElement('div')
    const blob = new Blob(['png'], { type: 'image/png' })
    vi.spyOn(annotator, 'getAnnotatedImage').mockResolvedValue({ blob, dataUrl: 'data:image/png;base64,X' })

    await annotator.attachScreenshot()

    expect(onAttach).toHaveBeenCalledTimes(1)
    expect(onAttach.mock.calls[0][0]).toMatchObject({ blob, mime_type: 'image/png' })
    expect(annotator.modal).toBeNull()
  })
})
