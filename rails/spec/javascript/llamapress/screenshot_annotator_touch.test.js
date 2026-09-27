import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

// Kody, 2026-09-27: on a phone, the screenshot button in the purple feedback
// bubble opened the "select an area" overlay, but dragging a finger across it
// drew nothing and captured nothing.
//
// Cause: the overlay listened for mousedown / mousemove / mouseup only. A finger
// drag delivers none of those — the browser treats it as a page scroll — so the
// selection box was never drawn and capture never started.
//
// The fix moves the overlay to Pointer Events (one path for mouse, touch and
// pen) and sets touch-action: none on it so the drag is not eaten by scrolling.
// Capture itself already works on phones: getDisplayMedia is missing there, so
// captureRegion falls back to html2canvas.

const MODULE = '../../../app/javascript/llamapress/screenshot_annotator.js'

let annotator

beforeEach(async () => {
  vi.resetModules()
  delete window.screenshotAnnotator
  document.body.innerHTML = '<div id="llamapress-feedback-bubble"></div>'
  window.llamapressHtml2canvas = vi.fn()
  window.fabric = {}
  await import(MODULE)
  annotator = window.screenshotAnnotator
})

afterEach(() => {
  vi.restoreAllMocks()
  vi.unstubAllGlobals()
  delete window.screenshotAnnotator
  delete window.llamapressHtml2canvas
  delete window.fabric
  document.body.innerHTML = ''
})

const overlay = () => document.getElementById('screenshot-selection-overlay')

function pointer(target, type, pointerType, x, y) {
  target.dispatchEvent(new PointerEvent(type, {
    bubbles: true, cancelable: true, pointerType, pointerId: 1, clientX: x, clientY: y,
  }))
}

function drag(pointerType, from, to) {
  const el = overlay()
  pointer(el, 'pointerdown', pointerType, ...from)
  pointer(el, 'pointermove', pointerType, ...to)
  // happy-dom does no layout; give the drawn box the size it would have.
  vi.spyOn(HTMLElement.prototype, 'getBoundingClientRect').mockReturnValue({
    left: Math.min(from[0], to[0]), top: Math.min(from[1], to[1]),
    width: Math.abs(to[0] - from[0]), height: Math.abs(to[1] - from[1]),
  })
  pointer(el, 'pointerup', pointerType, ...to)
}

function stubPrimaryInput(kind) {
  vi.stubGlobal('matchMedia', (query) => ({
    matches: query === '(hover: none)' && kind === 'touch',
    media: query,
    addEventListener() {},
    removeEventListener() {},
  }))
}

describe('screenshot area selection on a touchscreen', () => {
  it('a finger drag captures the dragged region', async () => {
    await annotator.startCapture(vi.fn())
    const capture = vi.spyOn(annotator, 'captureRegion').mockResolvedValue('data:image/png;base64,x')
    vi.spyOn(annotator, 'showAnnotationModal').mockImplementation(() => {})

    drag('touch', [20, 40], [220, 300])

    await vi.waitFor(() => expect(capture).toHaveBeenCalled())
    expect(capture).toHaveBeenCalledWith(20, 40, 200, 260)
    expect(overlay()).toBeNull()
  })

  it('draws the selection box while the finger is still moving', async () => {
    await annotator.startCapture(vi.fn())

    pointer(overlay(), 'pointerdown', 'touch', 10, 10)
    pointer(overlay(), 'pointermove', 'touch', 110, 60)

    const box = overlay().querySelector('[data-screenshot-selection-box]')
    expect(box).not.toBeNull()
    expect(box.style.width).toBe('100px')
    expect(box.style.height).toBe('50px')
  })

  it('stops the page scrolling under the drag', async () => {
    await annotator.startCapture(vi.fn())

    expect(overlay().style.touchAction).toBe('none')
  })

  it('tells a touch user to drag, not click', async () => {
    stubPrimaryInput('touch')
    await annotator.startCapture(vi.fn())

    expect(overlay().textContent).toContain('Drag to select area')
    expect(overlay().textContent).not.toContain('Click and drag')
  })

  // Kody, 2026-09-27: on iPhone Safari, starting a drag near the left edge fired
  // the browser's back-swipe and navigated away mid-selection. touch-action: none
  // does not stop that gesture on iOS; cancelling touchstart does. Pointer events
  // still arrive, so the drag itself is unaffected.
  it('cancels touchstart so an edge drag cannot trigger the iOS back/forward swipe', async () => {
    await annotator.startCapture(vi.fn())

    const e = new TouchEvent('touchstart', { bubbles: true, cancelable: true })
    overlay().dispatchEvent(e)

    expect(e.defaultPrevented).toBe(true)
  })

  it('leaves touchstart on the Cancel button alone, so it can still be tapped', async () => {
    await annotator.startCapture(vi.fn())

    const e = new TouchEvent('touchstart', { bubbles: true, cancelable: true })
    document.getElementById('screenshot-cancel').dispatchEvent(e)

    expect(e.defaultPrevented).toBe(false)
  })

  it('a tiny accidental tap does not capture', async () => {
    await annotator.startCapture(vi.fn())
    const capture = vi.spyOn(annotator, 'captureRegion')

    drag('touch', [50, 50], [53, 52])

    expect(capture).not.toHaveBeenCalled()
    expect(overlay()).not.toBeNull()
  })
})

describe('screenshot area selection with a mouse (unchanged behaviour)', () => {
  it('a mouse drag still captures the dragged region', async () => {
    stubPrimaryInput('mouse')
    await annotator.startCapture(vi.fn())
    const capture = vi.spyOn(annotator, 'captureRegion').mockResolvedValue('data:image/png;base64,x')
    vi.spyOn(annotator, 'showAnnotationModal').mockImplementation(() => {})

    expect(overlay().textContent).toContain('Click and drag to select area')

    drag('mouse', [300, 200], [100, 50])

    await vi.waitFor(() => expect(capture).toHaveBeenCalled())
    expect(capture).toHaveBeenCalledWith(100, 50, 200, 150)
  })
})
