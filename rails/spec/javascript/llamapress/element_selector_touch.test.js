import { describe, it, expect, beforeEach, afterEach } from 'vitest'

// Nicole Haldis (sipstaff.com) and Jennie Morgan (goconnexa.com), both on box
// leo-borro, reported 2026-09-11 that the pointer / select-element icon in the
// purple feedback bubble "wasn't working" on Safari on an iPhone and on one other
// non-Chrome engine.
//
// Cause: element_selector.js bound exactly three listeners — mousemove, click and
// keydown — and nothing else. A touchscreen has none of those natively; the feature
// only ever "worked" on a phone because Chromium synthesises a compatibility
// mousemove + click from a tap. Three defects followed:
//
//   1. The only way out of selection mode was the Escape key, and enabling it drew
//      NOTHING on screen while the caller had already hidden the feedback panel. On
//      a phone that is an invisible mode with no exit but a page reload.
//   2. The green hover highlight is driven by mousemove, so on touch it appeared
//      only at the instant of the tap — you could not see what you were about to
//      pick before picking it.
//   3. WebKit does not synthesise a click from a tap on a non-interactive element
//      unless it looks clickable; this file sets cursor:crosshair, which is not one
//      of the heuristics. On iOS Safari a tap on a plain <p> plausibly produced
//      nothing at all.
//
// The fix moves the picker to Pointer Events (one path for mouse, touch and pen),
// makes touch a two-step tap-to-highlight-then-confirm, and — the part worth
// shipping on every engine — draws a banner with a visible Cancel button.
//
// These tests own that contract. Against the pre-fix file every touch case below
// fails, because nothing is listening for pointer events at all.

const MODULE = '../../../app/javascript/llamapress/element_selector.js'

const BANNER_ID = 'llamapress-element-selector-banner'

let selector

async function freshSelector() {
  const mod = await import(MODULE)
  return mod
}

/** A real pointer sequence, the way a finger or a mouse actually delivers one. */
function pointer(target, type, pointerType) {
  target.dispatchEvent(new PointerEvent(type, { bubbles: true, cancelable: true, pointerType }))
}

function tap(target) {
  pointer(target, 'pointerdown', 'touch')
  pointer(target, 'pointerup', 'touch')
}

function mouseClick(target) {
  pointer(target, 'pointermove', 'mouse')
  pointer(target, 'pointerdown', 'mouse')
  pointer(target, 'pointerup', 'mouse')
}

function banner() {
  return document.getElementById(BANNER_ID)
}

describe('element selector on touch devices', () => {
  beforeEach(async () => {
    selector = await freshSelector()
    document.body.innerHTML = `
      <div id="page">
        <p id="plain">Tap me - I am a plain paragraph, not a link or a button.</p>
        <p id="other">Some other paragraph.</p>
      </div>
      <div id="llamapress-feedback-bubble"><button id="bubble-btn">bubble</button></div>
    `
  })

  afterEach(() => {
    selector.disableElementSelector()
    document.body.innerHTML = ''
  })

  it('arms a visible banner with a Cancel button, so a phone user is never stuck', () => {
    expect(banner()).toBeNull()

    selector.enableElementSelector({ onSelect: () => {}, onCancel: () => {} })

    const b = banner()
    expect(b).not.toBeNull()
    expect(b.querySelector('[data-element-selector-cancel]')).not.toBeNull()
  })

  it('tears the banner down again when the selector is disabled', () => {
    selector.enableElementSelector({ onSelect: () => {} })
    expect(banner()).not.toBeNull()

    selector.disableElementSelector()
    expect(banner()).toBeNull()
  })

  it('the banner Cancel button cancels the mode (an iPhone has no Escape key)', () => {
    let cancelled = false
    selector.enableElementSelector({ onSelect: () => {}, onCancel: () => { cancelled = true } })

    banner().querySelector('[data-element-selector-cancel]').click()

    expect(cancelled).toBe(true)
    expect(banner()).toBeNull()
    expect(document.body.classList.contains('element-selector-active')).toBe(false)
  })

  it('a tap HIGHLIGHTS the element rather than committing it blind', () => {
    const picked = []
    selector.enableElementSelector({ onSelect: (d) => picked.push(d) })

    const plain = document.getElementById('plain')
    tap(plain)

    // You can see what you are about to pick...
    expect(plain.classList.contains('element-selector-highlight')).toBe(true)
    // ...and nothing has been committed on that first tap.
    expect(picked).toHaveLength(0)
  })

  it('the banner confirm button commits the highlighted element', () => {
    const picked = []
    selector.enableElementSelector({ onSelect: (d) => picked.push(d) })

    const plain = document.getElementById('plain')
    tap(plain)
    banner().querySelector('[data-element-selector-confirm]').click()

    expect(picked).toHaveLength(1)
    expect(picked[0].text).toContain('Tap me')
    expect(picked[0].selector).toContain('#plain')
    expect(picked[0].html).toContain('Tap me')
  })

  it('tapping the same element a second time confirms it', () => {
    const picked = []
    selector.enableElementSelector({ onSelect: (d) => picked.push(d) })

    const plain = document.getElementById('plain')
    tap(plain)
    tap(plain)

    expect(picked).toHaveLength(1)
    expect(picked[0].selector).toContain('#plain')
  })

  it('tapping a DIFFERENT element moves the highlight instead of committing', () => {
    const picked = []
    selector.enableElementSelector({ onSelect: (d) => picked.push(d) })

    const plain = document.getElementById('plain')
    const other = document.getElementById('other')
    tap(plain)
    tap(other)

    expect(picked).toHaveLength(0)
    expect(plain.classList.contains('element-selector-highlight')).toBe(false)
    expect(other.classList.contains('element-selector-highlight')).toBe(true)
  })

  it('never selects the feedback bubble or its own banner', () => {
    const picked = []
    selector.enableElementSelector({ onSelect: (d) => picked.push(d) })

    tap(document.getElementById('bubble-btn'))
    tap(document.getElementById('bubble-btn'))
    tap(banner())
    tap(banner())

    expect(picked).toHaveLength(0)
  })

  it('stops the page scrolling out from under a drag while armed', () => {
    selector.enableElementSelector({ onSelect: () => {} })
    expect(document.body.style.touchAction).toBe('none')

    selector.disableElementSelector()
    expect(document.body.style.touchAction).not.toBe('none')
  })
})

describe('element selector on a mouse (unchanged behaviour)', () => {
  beforeEach(async () => {
    selector = await freshSelector()
    document.body.innerHTML = `<p id="plain">A plain paragraph.</p>`
  })

  afterEach(() => {
    selector.disableElementSelector()
    document.body.innerHTML = ''
  })

  it('highlights on hover', () => {
    selector.enableElementSelector({ onSelect: () => {} })

    const plain = document.getElementById('plain')
    pointer(plain, 'pointermove', 'mouse')

    expect(plain.classList.contains('element-selector-highlight')).toBe(true)
  })

  it('commits on a single mouse click - no confirm step', () => {
    const picked = []
    selector.enableElementSelector({ onSelect: (d) => picked.push(d) })

    mouseClick(document.getElementById('plain'))

    expect(picked).toHaveLength(1)
    expect(picked[0].text).toContain('A plain paragraph')
  })

  it('still cancels on Escape', () => {
    let cancelled = false
    selector.enableElementSelector({ onSelect: () => {}, onCancel: () => { cancelled = true } })

    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))

    expect(cancelled).toBe(true)
    expect(document.body.classList.contains('element-selector-active')).toBe(false)
  })
})
