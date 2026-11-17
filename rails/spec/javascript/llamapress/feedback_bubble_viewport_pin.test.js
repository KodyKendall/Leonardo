import { describe, it, expect, afterEach } from 'vitest'

// LP-26 (RSB feedback #502): on iPhone/iPad Safari a wide table makes the layout
// viewport wider than the screen. `position: fixed` resolves against that layout
// viewport, so the bubble floated over the table's delete icons and drifted with
// scrolling instead of sitting in the screen's bottom-right corner.
//
// The fix pins the bubble to window.visualViewport on touch devices only; the
// desktop bubble keeps its plain `fixed bottom-5 right-5` classes.

const MODULE = '../../../app/javascript/llamapress/feedback_bubble.js'

function fakeWindow({ coarse, viewport }) {
  const vv = viewport && Object.assign(new EventTarget(), viewport)
  return {
    matchMedia: (q) => ({ matches: coarse && q.includes('coarse') }),
    visualViewport: vv,
    addEventListener() {},
    removeEventListener() {},
  }
}

function bubble() {
  const el = document.createElement('div')
  el.className = 'fixed bottom-5 right-5 z-50'
  Object.defineProperty(el, 'offsetWidth', { value: 48 })
  Object.defineProperty(el, 'offsetHeight', { value: 48 })
  document.body.appendChild(el)
  return el
}

afterEach(() => { document.body.innerHTML = '' })

describe('feedback bubble viewport pinning', () => {
  it('leaves the desktop bubble on its fixed classes', async () => {
    const { pinToVisualViewport } = await import(MODULE)
    const el = bubble()
    pinToVisualViewport(el, fakeWindow({
      coarse: false,
      viewport: { offsetLeft: 0, offsetTop: 0, width: 1200, height: 800, scale: 1 },
    }))

    expect(el.getAttribute('style')).toBeNull()
    expect(el.classList.contains('bottom-5')).toBe(true)
  })

  it('anchors to the visible screen corner on touch, not the layout viewport', async () => {
    const { pinToVisualViewport } = await import(MODULE)
    const el = bubble()
    // User has scrolled the wide table 500px right and 300px down.
    pinToVisualViewport(el, fakeWindow({
      coarse: true,
      viewport: { offsetLeft: 500, offsetTop: 300, width: 867, height: 669, scale: 1 },
    }))

    expect(el.style.position).toBe('fixed')
    expect(el.style.right).toBe('auto')
    expect(el.style.bottom).toBe('auto')
    // right edge = 500 + 867 = 1367, minus the 48px bubble, minus 20px margin
    expect(el.style.left).toBe('1299px')
    expect(el.style.top).toBe('901px')
    expect(el.hasAttribute('data-vv-pinned')).toBe(true)
  })

  it('clears the notch / home bar via safe-area insets once pinned', async () => {
    const { createBubbleHTML } = await import(MODULE)
    document.body.innerHTML = createBubbleHTML()
    const css = [...document.querySelectorAll('#llamapress-feedback-bubble style')]
      .map(s => s.textContent).join('\n')
    const rule = css.match(/\[data-vv-pinned\]\s*\{([^}]*)\}/)
    expect(rule, 'a [data-vv-pinned] rule').not.toBeNull()
    expect(rule[1]).toContain('env(safe-area-inset-right')
    expect(rule[1]).toContain('env(safe-area-inset-bottom')
  })

  it('follows the visual viewport when it scrolls or resizes', async () => {
    const { pinToVisualViewport } = await import(MODULE)
    const el = bubble()
    const win = fakeWindow({
      coarse: true,
      viewport: { offsetLeft: 0, offsetTop: 0, width: 400, height: 700, scale: 1 },
    })
    pinToVisualViewport(el, win)
    expect(el.style.top).toBe('632px')

    win.visualViewport.offsetTop = 1000
    win.visualViewport.dispatchEvent(new Event('scroll'))
    expect(el.style.top).toBe('1632px')

    win.visualViewport.height = 400 // keyboard opened
    win.visualViewport.dispatchEvent(new Event('resize'))
    expect(el.style.top).toBe('1332px')
  })

  it('keeps its on-screen size when pinch-zoomed', async () => {
    const { pinToVisualViewport } = await import(MODULE)
    const el = bubble()
    pinToVisualViewport(el, fakeWindow({
      coarse: true,
      viewport: { offsetLeft: 0, offsetTop: 0, width: 200, height: 300, scale: 2 },
    }))

    expect(el.style.transform).toBe('scale(0.5)')
    expect(el.style.transformOrigin).toBe('bottom right')
  })

  it('stops listening once the bubble leaves the page (Turbo swap)', async () => {
    const { pinToVisualViewport } = await import(MODULE)
    const el = bubble()
    const win = fakeWindow({
      coarse: true,
      viewport: { offsetLeft: 0, offsetTop: 0, width: 400, height: 700, scale: 1 },
    })
    const unpin = pinToVisualViewport(el, win)
    unpin()

    win.visualViewport.offsetTop = 1000
    win.visualViewport.dispatchEvent(new Event('scroll'))
    expect(el.style.top).toBe('632px')
  })
})
