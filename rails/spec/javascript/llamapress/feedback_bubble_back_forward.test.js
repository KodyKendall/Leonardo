import { describe, it, expect, beforeEach, vi } from 'vitest'

// 2026-11-21 (RSB, Richard on his phone): after Back/Forward the bubble showed but did
// nothing when tapped. Turbo restores a CLONE of the page it cached, and a clone has no
// listeners; init saw "a bubble is already there" and returned. LP-57 page comments
// live in that bubble, so it has to come back working.

const MODULE = '../../../app/javascript/llamapress/feedback_bubble.js'

beforeEach(() => {
  window.llamapressConfig = { feedbackBubbleEnabled: true, userLoggedIn: true }
  global.fetch = vi.fn(async () => ({ ok: true, status: 200, json: async () => ({}) }))
})

function panelOpens() {
  document.getElementById('feedback-trigger').click()
  return !document.getElementById('feedback-panel').classList.contains('hidden')
}

describe('feedback bubble after Back/Forward', () => {
  it('works again when Turbo restores a cached clone of the page', async () => {
    await import(MODULE)
    document.dispatchEvent(new Event('turbo:load'))
    const live = document.getElementById('llamapress-feedback-bubble')
    expect(live).not.toBeNull()

    // What Turbo does on Back: the snapshot (a deep clone) replaces the page.
    live.replaceWith(live.cloneNode(true))
    document.dispatchEvent(new Event('turbo:load'))

    expect(document.querySelectorAll('#llamapress-feedback-bubble').length).toBe(1)
    expect(panelOpens()).toBe(true)
  })

  it('takes itself out before Turbo caches the page', async () => {
    await import(MODULE)
    document.dispatchEvent(new Event('turbo:load'))
    expect(document.getElementById('llamapress-feedback-bubble')).not.toBeNull()

    document.dispatchEvent(new Event('turbo:before-cache'))
    expect(document.getElementById('llamapress-feedback-bubble')).toBeNull()

    document.dispatchEvent(new Event('turbo:load'))
    expect(document.querySelectorAll('#llamapress-feedback-bubble').length).toBe(1)
    expect(panelOpens()).toBe(true)
  })
})
