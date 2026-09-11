import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

// The feedback screenshot tool was dead on every Leo-built page (SI#479, instance
// 1663 / leo-mezuli). Camera icon -> drag a region -> the "Annotate Screenshot"
// modal opens, the canvas never paints, the tools do nothing, and Attach raises
// alert("Failed to attach screenshot") with the modal stuck over a hidden feedback
// panel. The only way out was a reload, which loses the typed feedback.
//
// Cause: html2canvas and fabric.js were <script> tags in exactly ONE layout,
// application.html.erb. screenshot_annotator.js comes in through the IMPORTMAP, so
// it loads under every layout. A module's dependency on two window globals was
// expressed only as a script tag in a sibling layout, and nothing linked them — so
// any other layout silently lost the feature. prototypes.html.erb (the layout for
// Leo-generated pages on every box) has the html2canvas tag commented out and no
// fabric tag at all: 155 of 155 running boxes affected, 90 of them also through a
// custom app layout Leo wrote.
//
// The fix is NOT to add the tags to more layouts — that regresses the moment Leo
// writes the next layout, and Leo writes layouts constantly. The module loads what
// it needs itself, which no new layout can undo.
//
// These tests own the two halves that matter: the module fetches its own
// dependencies, and a missing library degrades to an unannotated screenshot
// instead of a dead end.

const MODULE = '../../../app/javascript/llamapress/screenshot_annotator.js'

const FABRIC_SRC = 'https://cdnjs.cloudflare.com/ajax/libs/fabric.js/5.3.1/fabric.min.js'
const HTML2CANVAS_SRC = 'https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js'
const PNG = 'data:image/png;base64,iVBORw0KGgo='

/** Load a fresh copy of the module, so the in-flight-script cache starts empty. */
async function freshAnnotator() {
  vi.resetModules()
  delete window.screenshotAnnotator
  await import(MODULE)
  return window.screenshotAnnotator
}

/**
 * jsdom never fetches an injected <script>, so nothing would ever resolve. Stand in
 * for the network: every appended script fires load (or error) on the next tick.
 */
function autoRespondToScripts({ fail = false } = {}) {
  const seen = []
  const realAppend = document.head.appendChild.bind(document.head)
  vi.spyOn(document.head, 'appendChild').mockImplementation((node) => {
    if (node.tagName === 'SCRIPT') {
      seen.push(node.src)
      queueMicrotask(() => node.dispatchEvent(new Event(fail ? 'error' : 'load')))
    }
    return realAppend(node)
  })
  return seen
}

beforeEach(() => {
  document.head.innerHTML = ''
  document.body.innerHTML = ''
  delete window.fabric
  delete window.html2canvas
  // The raw-attach path turns the data URL into a blob; jsdom has no data: fetch.
  global.fetch = vi.fn(async () => ({ blob: async () => new Blob(['x'], { type: 'image/png' }) }))
})

afterEach(() => {
  vi.restoreAllMocks()
})

describe('loading its own dependencies', () => {
  it('injects both libraries when the layout provided neither', async () => {
    const injected = autoRespondToScripts()
    const annotator = await freshAnnotator()

    await annotator.ensureDependencies()

    expect(injected).toContain(HTML2CANVAS_SRC)
    expect(injected).toContain(FABRIC_SRC)
  })

  it('injects nothing when the layout already provided them', async () => {
    // application.html.erb still ships both tags. Boxes where the feature already
    // worked must not pay for a second copy of fabric on every capture.
    window.fabric = {}
    window.html2canvas = () => {}
    const injected = autoRespondToScripts()
    const annotator = await freshAnnotator()

    await annotator.ensureDependencies()

    expect(injected).toEqual([])
  })

  it('appends one tag per URL even when captures overlap', async () => {
    const injected = autoRespondToScripts()
    const annotator = await freshAnnotator()

    await Promise.all([
      annotator.ensureDependencies(),
      annotator.ensureDependencies(),
      annotator.ensureDependencies(),
    ])

    expect(injected.filter(src => src === FABRIC_SRC)).toHaveLength(1)
  })

  it('does not cache a FAILED load — the next capture retries', async () => {
    // A blocked CDN or a flaky network must not permanently disable the tool for
    // the life of the page.
    const failed = autoRespondToScripts({ fail: true })
    const annotator = await freshAnnotator()
    await annotator.ensureDependencies()
    expect(failed.filter(src => src === FABRIC_SRC)).toHaveLength(1)

    vi.restoreAllMocks()
    const retried = autoRespondToScripts()
    await annotator.ensureDependencies()

    expect(retried).toContain(FABRIC_SRC)
  })

  it('survives a dependency that never loads, rather than throwing', async () => {
    autoRespondToScripts({ fail: true })
    const annotator = await freshAnnotator()

    await expect(annotator.ensureDependencies()).resolves.toBeUndefined()
  })

  it('loads them on the capture CLICK, before the selection overlay', async () => {
    // Ordering is load-bearing: getDisplayMedia needs the region mouseup's user
    // activation, and an await in front of THAT would spend the gesture. Loading on
    // the button click means both libraries are in place by the time the drag ends.
    const annotator = await freshAnnotator()
    autoRespondToScripts()
    const order = []
    vi.spyOn(annotator, 'ensureDependencies').mockImplementation(async () => { order.push('deps') })
    vi.spyOn(annotator, 'showSelectionOverlay').mockImplementation(() => { order.push('overlay') })

    await annotator.startCapture(() => {})

    expect(order).toEqual(['deps', 'overlay'])
  })
})

describe('degrading when fabric is unavailable', () => {
  it('attaches the raw capture instead of opening a modal that cannot paint', async () => {
    const annotator = await freshAnnotator()
    const attached = vi.fn()
    annotator.onAttachCallback = attached

    annotator.showAnnotationModal(PNG)
    await vi.waitFor(() => expect(attached).toHaveBeenCalled())

    expect(document.getElementById('screenshot-annotation-modal')).toBeNull()
    const payload = attached.mock.calls[0][0]
    expect(payload.mime_type).toBe('image/png')
    expect(payload.dataUrl).toBe(PNG)
    expect(payload.blob).toBeInstanceOf(Blob)
  })

  it('gives the feedback bubble back, so the draft is not lost', async () => {
    // showSelectionOverlay() hides the bubble; the feedback panel only reopens from
    // the attach callback. Leaving both hidden is what forced the reload.
    const bubble = document.createElement('div')
    bubble.id = 'llamapress-feedback-bubble'
    bubble.style.display = 'none'
    document.body.appendChild(bubble)

    const annotator = await freshAnnotator()
    annotator.onAttachCallback = vi.fn()
    annotator.showAnnotationModal(PNG)

    await vi.waitFor(() => expect(bubble.style.display).toBe(''))
  })

  it('opens the real modal when fabric IS present', async () => {
    window.fabric = { Canvas: class {}, Image: { fromURL: () => {} } }
    const annotator = await freshAnnotator()
    annotator.onAttachCallback = vi.fn()

    annotator.showAnnotationModal(PNG)

    expect(document.getElementById('screenshot-annotation-modal')).not.toBeNull()
  })
})

describe('Attach when the canvas was never built', () => {
  it('attaches the unannotated capture instead of alerting and hanging', async () => {
    // getAnnotatedImage() returns null with no canvas, and attachScreenshot()
    // destructured it. The TypeError was caught only to alert() and return, leaving
    // the modal up over a hidden panel with no way out but a reload.
    const annotator = await freshAnnotator()
    const attached = vi.fn()
    annotator.onAttachCallback = attached
    annotator.originalImageData = PNG
    annotator.fabricCanvas = null
    annotator.modal = document.createElement('div')
    annotator.modal.id = 'screenshot-annotation-modal'
    document.body.appendChild(annotator.modal)

    const alerted = vi.fn()
    window.alert = alerted

    await annotator.attachScreenshot()

    expect(alerted).not.toHaveBeenCalled()
    expect(attached).toHaveBeenCalled()
    expect(document.getElementById('screenshot-annotation-modal')).toBeNull()
  })
})
