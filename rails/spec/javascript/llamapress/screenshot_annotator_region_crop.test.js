import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

// A screenshot taken from the purple feedback bubble came back showing the
// chat panel instead of the region the user dragged over.
//
// Cause: this page runs inside the chat's app-preview iframe, but
// getDisplayMedia captures the whole TAB. The selection's x/y are coordinates
// in THIS frame, and the scale was computed from THIS frame's innerWidth, so
// the crop was taken from the tab's top-left — one chat panel to the left of
// what was selected, and scaled up by the ratio between the two viewports.
//
// The fix asks the browser to trim the stream to this document first (Region
// Capture), which puts the captured pixels and the selection back in the same
// coordinate space. Where that isn't available the native capture can't be
// trusted to line up at all, so the region is rendered with html2canvas
// instead of cropped from the wrong place.

const MODULE = '../../../app/javascript/llamapress/screenshot_annotator.js'

// The browser tab: chat panel on the left, preview iframe on the right.
const TAB = { width: 1600, height: 900 }
const FRAME = { left: 587, top: 129, width: 1013, height: 771 }
// What the user dragged over, in frame coordinates.
const REGION = { x: 40, y: 60, width: 300, height: 200 }

function harness({ regionCapture = true, framed = true } = {}) {
  const calls = { cropTo: [], stopped: 0, html2canvas: [], drawImage: [] }

  if (framed) {
    Object.defineProperty(window, 'top', { value: { name: 'chat' }, configurable: true })
  } else {
    Object.defineProperty(window, 'top', { value: window, configurable: true })
  }

  const track = { stop() { calls.stopped += 1 } }
  if (regionCapture) {
    track.cropTo = async (target) => { calls.cropTo.push(target) }
    window.CropTarget = { fromElement: async (el) => ({ element: el }) }
  } else {
    delete window.CropTarget
  }

  const stream = { getVideoTracks: () => [track], getTracks: () => [track] }
  navigator.mediaDevices = { getDisplayMedia: vi.fn(async () => stream) }

  // This document's own viewport. Inside a frame that is NOT the tab.
  window.innerWidth = framed ? FRAME.width : TAB.width
  window.innerHeight = framed ? FRAME.height : TAB.height

  // The capture is the whole tab until something trims it — exactly what the
  // browser does (measured in Chromium: cropTo brought a 1600x900 tab capture
  // down to the 1013x771 preview frame).
  globalThis.ImageCapture = class {
    constructor() {}
    async grabFrame() {
      return calls.cropTo.length
        ? { width: FRAME.width, height: FRAME.height }
        : { width: TAB.width, height: TAB.height }
    }
  }

  // happy-dom does no layout, so a position:fixed inset:0 box measures 0x0.
  // A browser measures it as this document's viewport.
  const origRect = HTMLElement.prototype.getBoundingClientRect
  vi.spyOn(HTMLElement.prototype, 'getBoundingClientRect').mockImplementation(function () {
    if (this.id !== 'screenshot-crop-box') return origRect.call(this)
    return { left: 0, top: 0, width: window.innerWidth, height: window.innerHeight }
  })

  // Record what gets cropped out of the captured frame.
  const origCreateElement = document.createElement.bind(document)
  vi.spyOn(document, 'createElement').mockImplementation((tag) => {
    const el = origCreateElement(tag)
    if (tag === 'canvas') {
      el.getContext = () => ({ drawImage: (...args) => calls.drawImage.push(args) })
      el.toDataURL = () => 'data:image/png;base64,NATIVE'
    }
    return el
  })

  window.html2canvas = vi.fn(async (node, opts) => {
    calls.html2canvas.push(opts)
    return { toDataURL: () => 'data:image/png;base64,HTML2CANVAS' }
  })

  return { calls }
}

/** The source rectangle taken out of the captured frame. */
function sourceRect(calls) {
  const args = calls.drawImage.find(a => a.length === 9)
  return args ? args.slice(1, 5) : null
}

let annotator

beforeEach(async () => {
  vi.resetModules()
  delete window.screenshotAnnotator
  await import(MODULE)
  annotator = window.screenshotAnnotator
})

afterEach(() => {
  vi.restoreAllMocks()
  delete window.screenshotAnnotator
  delete window.CropTarget
  delete window.html2canvas
  delete globalThis.ImageCapture
})

describe('captureRegion inside the chat preview iframe', () => {
  it('trims the captured stream to this document, so the crop is the region the user drew', async () => {
    const { calls } = harness({ regionCapture: true })

    const dataUrl = await annotator.captureRegion(REGION.x, REGION.y, REGION.width, REGION.height)

    expect(calls.cropTo).toHaveLength(1)
    // Cropped to a viewport-sized fixed box, not documentElement (the whole
    // page, which is scrolled and a different size from the window).
    expect(calls.cropTo[0].element.id).toBe('screenshot-crop-box')
    expect(document.getElementById('screenshot-crop-box')).toBeNull()
    expect(dataUrl).toBe('data:image/png;base64,NATIVE')

    // Frame coordinates onto frame pixels: 1:1, no chat panel in front of them.
    expect(sourceRect(calls)).toEqual([REGION.x, REGION.y, REGION.width, REGION.height])
    expect(calls.stopped).toBe(1)
  })

  it('falls back to html2canvas when the browser cannot trim the stream', async () => {
    const { calls } = harness({ regionCapture: false })

    const dataUrl = await annotator.captureRegion(REGION.x, REGION.y, REGION.width, REGION.height)

    // An untrimmed tab capture would be cropped from the tab's top-left — the
    // chat panel. Rendering this document instead is the only thing that lines
    // up with what the user dragged over.
    expect(dataUrl).toBe('data:image/png;base64,HTML2CANVAS')
    expect(sourceRect(calls)).toBeNull()
    expect(calls.html2canvas[0]).toMatchObject({ width: REGION.width, height: REGION.height })
    expect(calls.stopped).toBe(1)
  })

  it('leaves a top-level page alone — its coordinates already match the capture', async () => {
    const { calls } = harness({ regionCapture: true, framed: false })

    const dataUrl = await annotator.captureRegion(REGION.x, REGION.y, REGION.width, REGION.height)

    expect(calls.cropTo).toHaveLength(0)
    expect(dataUrl).toBe('data:image/png;base64,NATIVE')
    expect(calls.html2canvas).toHaveLength(0)
    expect(sourceRect(calls)).toEqual([REGION.x, REGION.y, REGION.width, REGION.height])
  })
})
