import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

// The feedback bubble's annotator silently refused to draw, and dragged the marks
// you had already made (reported with item 1 of SI 2026-09-11, leo-borro).
//
// Cause: all three shape tools opened their mouse-down handler with
//
//     this.fabricCanvas.on('mouse:down', (opt) => {
//       if (opt.target) return;
//
// opt.target is whatever Fabric hit-tested under the cursor, and every annotation
// was added with selectable: true. An arrow's hit area is the whole rectangle its
// diagonal spans — a modest arrow claimed a 183x123 px dead zone. So starting a
// second arrow anywhere near the first drew nothing, and because the object was
// selectable, Fabric took the drag for itself and hauled the first arrow across
// the screenshot instead.
//
// Marking up two things near each other hit this immediately, which is most of what
// "not a very good user experience" meant.
//
// The fix: a drawing tool draws, full stop. Annotations are deafened while a drawing
// tool is armed and re-armed by an explicit Move tool, so repositioning is still
// possible but only when you ask for it.

const MODULE = '../../../app/javascript/llamapress/screenshot_annotator.js'

/** Minimal stand-in for the parts of fabric.js these tools actually touch. */
function fakeFabric() {
  class Obj {
    constructor(props = {}) { Object.assign(this, props) }
    set(props) { Object.assign(this, props); return this }
  }
  return {
    Rect: class extends Obj { constructor(p) { super(p); this.type = 'rect' } },
    Line: class extends Obj { constructor(points, p) { super(p); this.type = 'line'; this.points = points } },
    Polygon: class extends Obj { constructor(points, p) { super(p); this.type = 'polygon'; this.points = points } },
    Group: class extends Obj { constructor(children, p) { super(p); this.type = 'group'; this.children = children } },
    IText: class extends Obj {
      constructor(text, p) { super(p); this.type = 'i-text'; this.text = text }
      enterEditing() {}
      selectAll() {}
    },
    PencilBrush: class { constructor() { this.color = null; this.width = null } },
  }
}

/** Stand-in canvas that records handlers so a test can drive a real gesture. */
function fakeCanvas() {
  const handlers = {}
  const objects = []
  return {
    isDrawingMode: false,
    selection: true,
    defaultCursor: 'default',
    freeDrawingBrush: null,
    activeObject: null,
    pointer: { x: 0, y: 0 },

    on(name, fn) { (handlers[name] ||= []).push(fn) },
    off(name) { delete handlers[name] },
    fire(name, opt) { (handlers[name] || []).forEach(fn => fn(opt)) },

    add(obj) { objects.push(obj) },
    remove(obj) { const i = objects.indexOf(obj); if (i >= 0) objects.splice(i, 1) },
    getObjects() { return objects },
    getPointer() { return this.pointer },
    renderAll() {},
    setActiveObject(obj) { this.activeObject = obj },
    discardActiveObject() { this.activeObject = null },
  }
}

let annotator
let canvas

/** Drive a press-drag-release with the pointer in canvas space. */
function drag(from, to, { target = null } = {}) {
  canvas.pointer = { ...from }
  canvas.fire('mouse:down', { e: {}, target })
  canvas.pointer = { ...to }
  canvas.fire('mouse:move', { e: {}, target })
  canvas.fire('mouse:up', { e: {}, target })
}

beforeEach(async () => {
  vi.resetModules()
  delete window.screenshotAnnotator
  window.fabric = fakeFabric()
  document.body.innerHTML = '<div id="fake-modal"></div>'

  await import(MODULE)
  annotator = window.screenshotAnnotator
  canvas = fakeCanvas()
  annotator.fabricCanvas = canvas
  annotator.modal = document.getElementById('fake-modal')
})

afterEach(() => {
  delete window.fabric
  delete window.screenshotAnnotator
  document.body.innerHTML = ''
  vi.useRealTimers()
})

describe('drawing on top of an existing annotation', () => {
  it('draws a second arrow that starts over the first one', () => {
    annotator.setTool('arrow')
    drag({ x: 20, y: 20 }, { x: 200, y: 140 })
    expect(canvas.getObjects()).toHaveLength(1)

    // Start inside the first arrow's bounding box — the case that drew nothing.
    const existing = canvas.getObjects()[0]
    annotator.setTool('arrow')
    drag({ x: 80, y: 80 }, { x: 300, y: 250 }, { target: existing })

    expect(canvas.getObjects()).toHaveLength(2)
  })

  it('draws a rectangle that starts over an existing annotation', () => {
    annotator.setTool('arrow')
    drag({ x: 20, y: 20 }, { x: 200, y: 140 })
    const existing = canvas.getObjects()[0]

    annotator.setTool('rectangle')
    drag({ x: 60, y: 60 }, { x: 260, y: 200 }, { target: existing })

    expect(canvas.getObjects()).toHaveLength(2)
  })

  it('places text on top of an existing annotation', () => {
    vi.useFakeTimers()
    annotator.setTool('arrow')
    drag({ x: 20, y: 20 }, { x: 200, y: 140 })
    const existing = canvas.getObjects()[0]

    annotator.setTool('text')
    canvas.pointer = { x: 90, y: 90 }
    canvas.fire('mouse:down', { e: {}, target: existing })

    expect(canvas.getObjects()).toHaveLength(2)
  })
})

describe('annotations do not move while a drawing tool is armed', () => {
  it('creates new shapes that Fabric cannot pick up and drag', () => {
    annotator.setTool('arrow')
    drag({ x: 20, y: 20 }, { x: 200, y: 140 })

    const arrow = canvas.getObjects()[0]
    expect(arrow.selectable).toBe(false)
    expect(arrow.evented).toBe(false)
  })

  it('deafens annotations already on the canvas when a drawing tool is picked', () => {
    annotator.setTool('arrow')
    drag({ x: 20, y: 20 }, { x: 200, y: 140 })
    const arrow = canvas.getObjects()[0]

    // Even if something re-armed it, arming a drawing tool must deafen it again.
    arrow.selectable = true
    arrow.evented = true
    annotator.setTool('rectangle')

    expect(arrow.selectable).toBe(false)
    expect(arrow.evented).toBe(false)
  })

  it('the Move tool re-arms them, so repositioning is still possible on purpose', () => {
    annotator.setTool('arrow')
    drag({ x: 20, y: 20 }, { x: 200, y: 140 })
    const arrow = canvas.getObjects()[0]

    annotator.setTool('move')

    expect(arrow.selectable).toBe(true)
    expect(arrow.evented).toBe(true)
    expect(canvas.selection).toBe(true)
  })
})

describe('the arrow tool always leaves a mark', () => {
  it('a click with no drag draws a short default arrow instead of nothing', () => {
    annotator.setTool('arrow')
    canvas.pointer = { x: 100, y: 100 }
    canvas.fire('mouse:down', { e: {}, target: null })
    canvas.fire('mouse:up', { e: {}, target: null })

    expect(canvas.getObjects()).toHaveLength(1)
  })
})

describe('the toolbar offers the Move tool', () => {
  it('renders a move button alongside the drawing tools', async () => {
    // The Move tool is the escape hatch for "your annotations are deafened while you
    // draw" — it has to be reachable in the toolbar, not merely callable in code.
    const source = (await import(MODULE + '?raw')).default

    expect(source).toContain('data-tool="move"')
    expect(source).toContain('data-tool="arrow"')
  })
})
