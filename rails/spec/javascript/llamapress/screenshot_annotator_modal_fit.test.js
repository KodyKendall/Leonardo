import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

// Kody, 2026-09-27: on a phone the captured region was "cut off" in the annotate
// modal, so it could not be reviewed.
//
// Cause, reproduced in phone emulation with a tall selection: the canvas was sized
// to 85% x 70% of window.innerWidth/innerHeight, ignoring the modal's own header,
// toolbar and footer (~220px). On a phone that pushes the canvas taller than the
// space left for it, and the canvas area centred with align-items/justify-content
// — which clips an overflowing child on BOTH sides and leaves the top unscrollable.
// iOS Safari makes it worse: innerHeight / 95vh are measured against the viewport
// with the toolbar hidden, so the modal ran under the visible toolbar too.
//
// The fix sizes the canvas to the space the modal really has on the VISIBLE
// screen (visualViewport minus the modal chrome), caps the card at 95dvh, and
// centres with margin:auto, which never clips.

const MODULE = '../../../app/javascript/llamapress/screenshot_annotator.js'

let annotator

beforeEach(async () => {
  vi.resetModules()
  delete window.screenshotAnnotator
  window.fabric = { Canvas: class {}, Image: { fromURL: () => {} } }
  await import(MODULE)
  annotator = window.screenshotAnnotator
  annotator.onAttachCallback = vi.fn()
})

afterEach(() => {
  vi.restoreAllMocks()
  vi.unstubAllGlobals()
  delete window.screenshotAnnotator
  delete window.fabric
  document.body.innerHTML = ''
})

function openModalWithChrome({ cardHeight, containerHeight }) {
  annotator.showAnnotationModal('data:image/png;base64,x')
  const card = document.querySelector('[data-annotation-card]')
  const container = document.getElementById('annotation-canvas-container')
  vi.spyOn(card, 'getBoundingClientRect').mockReturnValue({ height: cardHeight, width: 370 })
  vi.spyOn(container, 'getBoundingClientRect').mockReturnValue({ height: containerHeight, width: 368 })
  return { card, container }
}

describe('annotate modal on a phone', () => {
  it('fits a tall capture inside the VISIBLE screen, net of the modal chrome', () => {
    // iPhone: layout viewport taller than what is actually visible.
    vi.stubGlobal('innerWidth', 390)
    vi.stubGlobal('innerHeight', 800)
    vi.stubGlobal('visualViewport', { width: 390, height: 600 })
    // Header + toolbar + footer = 400 - 180 = 220px of chrome.
    openModalWithChrome({ cardHeight: 400, containerHeight: 180 })

    // A 300x500 CSS-px selection captured at 3x.
    const { width, height } = annotator.canvasSizeFor(900, 1500)

    // 600 * 0.95 visible - 220 chrome - 32 padding = 318px for the canvas.
    expect(height).toBeLessThanOrEqual(318)
    expect(height).toBeGreaterThan(300)
    expect(width / height).toBeCloseTo(900 / 1500, 2)
  })

  it('fits a wide capture to the visible width', () => {
    vi.stubGlobal('innerWidth', 390)
    vi.stubGlobal('visualViewport', { width: 390, height: 700 })
    openModalWithChrome({ cardHeight: 400, containerHeight: 180 })

    const { width } = annotator.canvasSizeFor(1170, 300)

    // 390 * 0.95 - 2px border - 32 padding
    expect(width).toBeLessThanOrEqual(337)
    expect(width).toBeGreaterThan(320)
  })

  it('never upscales a small capture', () => {
    vi.stubGlobal('visualViewport', { width: 1400, height: 900 })
    openModalWithChrome({ cardHeight: 400, containerHeight: 180 })

    expect(annotator.canvasSizeFor(120, 80)).toEqual({ width: 120, height: 80 })
  })

  it('caps the card at the dynamic viewport height, not the toolbar-hidden 95vh', () => {
    annotator.showAnnotationModal('data:image/png;base64,x')

    expect(document.querySelector('[data-annotation-card]').getAttribute('style')).toContain('95dvh')
  })

  it('centres the canvas with margin:auto, which cannot clip an oversized canvas', () => {
    annotator.showAnnotationModal('data:image/png;base64,x')

    const container = document.getElementById('annotation-canvas-container')
    expect(container.getAttribute('style')).not.toMatch(/align-items:\s*center/)
    expect(container.getAttribute('style')).not.toMatch(/justify-content:\s*center/)
    expect(annotator.modal.querySelector('style').textContent)
      .toMatch(/#annotation-canvas-container > \*\s*\{[^}]*margin:\s*auto/)
  })
})
