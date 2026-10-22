import { describe, it, expect, afterEach } from 'vitest'
import {
  screenAnonymousFiles,
  ANON_IMAGE_LIMIT,
  ANON_IMAGE_MAX_BYTES,
} from '../../../app/javascript/llamapress/anonymous_attachments.js'

// leo-furez / LP-9 (0.7.15). A signed-out visitor could pick an element and paste an
// image, press Send, see "sent" — and the server had thrown both away. The server now
// keeps the element and up to 3 images (PNG/JPEG/WebP/GIF, 5 MB each). The bubble has
// to offer exactly that: the picker, the screenshot button and an images-only
// paperclip, never the video button, and refuse in the browser any file the server
// would refuse, so nothing looks attached and then quietly vanishes.

const BUBBLE = '../../../app/javascript/llamapress/feedback_bubble.js'

afterEach(() => {
  document.body.innerHTML = ''
  delete window.llamapressConfig
})

async function renderBubble({ userLoggedIn }) {
  window.llamapressConfig = { feedbackBubbleEnabled: true, anonymousFeedbackEnabled: true, userLoggedIn }
  const { createBubbleHTML, applyAnonymousRestrictions } = await import(BUBBLE)
  document.body.innerHTML = createBubbleHTML()
  applyAnonymousRestrictions()
}

const hidden = (el) => el.classList.contains('hidden')
const paperclip = () => document.getElementById('feedback-file').closest('label')

describe('bubble controls for a signed-out visitor', () => {
  it('shows the element picker, screenshot and paperclip, and hides video', async () => {
    await renderBubble({ userLoggedIn: false })

    expect(hidden(document.getElementById('feedback-select-element-btn'))).toBe(false)
    expect(hidden(document.getElementById('feedback-screenshot-btn'))).toBe(false)
    expect(hidden(paperclip())).toBe(false)
    expect(hidden(document.getElementById('feedback-video-btn'))).toBe(true)
  })

  it('narrows the paperclip to images', async () => {
    await renderBubble({ userLoggedIn: false })
    expect(document.getElementById('feedback-file').getAttribute('accept')).toBe('image/*')
  })

  it('leaves a signed-in user every control and file type', async () => {
    await renderBubble({ userLoggedIn: true })

    expect(hidden(document.getElementById('feedback-video-btn'))).toBe(false)
    expect(document.getElementById('feedback-file').getAttribute('accept')).toContain('.pdf')
  })
})

describe('screenAnonymousFiles', () => {
  const file = (name, type, size = 10) => new File([new Uint8Array(size)], name, { type })

  it('keeps PNG, JPEG, WebP and GIF', () => {
    const files = [file('a.png', 'image/png'), file('b.jpg', 'image/jpeg'), file('c.webp', 'image/webp')]
    expect(screenAnonymousFiles(files)).toEqual({ accepted: files, refused: [] })
    expect(screenAnonymousFiles([file('d.gif', 'image/gif')]).refused).toEqual([])
  })

  it('refuses anything that is not one of those images, with a reason', () => {
    const { accepted, refused } = screenAnonymousFiles([
      file('photo.pdf', 'application/pdf'),
      file('logo.svg', 'image/svg+xml'),
      file('clip.webm', 'video/webm'),
    ])
    expect(accepted).toEqual([])
    expect(refused).toEqual([
      'photo.pdf: not an image',
      'logo.svg: not an image',
      'clip.webm: not an image',
    ])
  })

  it('refuses an image over the size cap', () => {
    const big = file('big.png', 'image/png', ANON_IMAGE_MAX_BYTES + 1)
    expect(screenAnonymousFiles([big]).refused).toEqual(['big.png: over 5 MB'])
  })

  it('keeps the first three images and refuses the rest', () => {
    const files = [1, 2, 3, 4].map((n) => file(`${n}.png`, 'image/png'))
    const { accepted, refused } = screenAnonymousFiles(files)
    expect(accepted).toHaveLength(ANON_IMAGE_LIMIT)
    expect(refused).toEqual(['4.png: only 3 images allowed'])
  })
})
