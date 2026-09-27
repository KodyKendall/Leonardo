import { describe, it, expect, afterEach } from 'vitest'

// Kody, 2026-09-27: on a phone the purple feedback bubble's action icons (pick an
// element, screenshot, record video, attach a file) were 16px icons with no
// padding — far below the ~44px a fingertip needs, so taps kept missing.
//
// The fix enlarges them only on touch-primary devices (pointer: coarse), so the
// desktop bubble looks exactly as before.

const MODULE = '../../../app/javascript/llamapress/feedback_bubble.js'

afterEach(() => { document.body.innerHTML = '' })

async function renderBubble() {
  const { createBubbleHTML } = await import(MODULE)
  document.body.innerHTML = createBubbleHTML()
}

const ACTIONS = [
  'feedback-select-element-btn',
  'feedback-screenshot-btn',
  'feedback-video-btn',
]

describe('feedback bubble action buttons on a touchscreen', () => {
  it('carries a touch-only rule giving each action a finger-sized target', async () => {
    await renderBubble()

    const css = [...document.querySelectorAll('#llamapress-feedback-bubble style')]
      .map(s => s.textContent).join('\n')
    const coarse = css.match(/@media\s*\(pointer:\s*coarse\)\s*\{([\s\S]*)\}/)
    expect(coarse, 'a (pointer: coarse) block').not.toBeNull()

    const block = coarse[1]
    expect(block).toMatch(/\[data-feedback-action\][^{]*\{[^}]*min-width:\s*44px/)
    expect(block).toMatch(/\[data-feedback-action\][^{]*\{[^}]*min-height:\s*44px/)
    expect(block).toMatch(/\[data-feedback-action\] svg[^{]*\{[^}]*width:\s*24px/)
  })

  it('tags every action — including the paperclip — so the rule reaches it', async () => {
    await renderBubble()

    for (const id of ACTIONS) {
      expect(document.getElementById(id).hasAttribute('data-feedback-action'), id).toBe(true)
    }
    const paperclip = document.getElementById('feedback-file').closest('label')
    expect(paperclip.hasAttribute('data-feedback-action')).toBe(true)
  })
})
