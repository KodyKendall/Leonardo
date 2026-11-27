import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

// LP-57: page comments. Anchoring (quote + 40-char context, never touching page text),
// shadow-DOM pins hidden by default, Turbo teardown, XSS-safe rendering, and the
// open-comment list handed to Leo.

const MODULE = '../../../app/javascript/llamapress/page_comments.js'

function page(html) {
  document.body.innerHTML = html
  return document.body
}

function bubble() {
  const b = document.createElement('div')
  b.id = 'llamapress-feedback-bubble'
  b.innerHTML = '<button id="feedback-trigger">Feedback</button><div id="feedback-panel" class="hidden"><div id="content-feedback"><form></form></div></div>'
  document.body.appendChild(b)
  return b
}

function selectText(node, start, end, endNode = node) {
  const r = document.createRange()
  r.setStart(node, start)
  r.setEnd(endNode, end)
  return r
}

function comment(id, attrs = {}) {
  return {
    id, body: `Comment ${id}`, quote: 'Annual plan', prefix: '', suffix: '', selector: null, label: null,
    page_path: '/pricing', state: 'attached', status: 'open', resolved: false,
    created_at: '2026-11-25T10:46:07Z', author: { id: 1, name: 'Ana Lima', initial: 'A' },
    mine: true, can_delete: true, replies: [], ...attrs
  }
}

function mockApi(comments) {
  const calls = []
  global.fetch = vi.fn(async (url, opts = {}) => {
    calls.push({ url, method: opts.method || 'GET', body: opts.body ? JSON.parse(opts.body) : null })
    const json = (opts.method || 'GET') === 'GET'
      ? { me: { id: 2, name: 'Ben', initial: 'B', admin: false }, comments }
      : { comment: comments[0] }
    return { ok: true, status: 200, json: async () => json }
  })
  return calls
}

let mod
beforeEach(async () => {
  mod = await import(MODULE)
  mod.teardown()
  window.llamapressConfig = { pageCommentsEnabled: true, pageCommentsUrl: '/llama_bot/page_comments' }
  try { window.localStorage.clear() } catch (_) { /* none */ }
  window.history.replaceState(null, '', '/pricing')
})

afterEach(() => {
  mod.teardown()
  delete window.llamapressConfig
  document.body.innerHTML = ''
})

describe('anchoring helpers', () => {
  it('normalizes page paths', () => {
    expect(mod.normalizePath('/pricing/')).toBe('/pricing')
    expect(mod.normalizePath('/pricing?x=1#y')).toBe('/pricing')
    expect(mod.normalizePath('')).toBe('/')
  })

  it('indexes visible text only: no script, style, bubble or injected UI', () => {
    page(`<main><p>Hello   <b>world</b></p><script>var secret = 1</script><style>.x{}</style>
          <div data-lp-injected>pin text</div><p>Bye</p></main>`)
    bubble()
    const T = mod.buildText()
    expect(T.text).toContain('Hello world')
    expect(T.text).toContain('Bye')
    expect(T.text).not.toContain('secret')
    expect(T.text).not.toContain('pin text')
    expect(T.text).not.toContain('Feedback')
  })

  it('captures the quote and context from text nodes, never from <script>', () => {
    page('<p id="a">Choose the Annual plan</p><script>LEAK()</script><p id="b">for $99 a year</p>')
    const a = document.getElementById('a').firstChild
    const b = document.getElementById('b').firstChild
    const got = mod.captureFromRange(selectText(a, 11, 3, b))
    expect(got.quote).toBe('Annual plan for')
    expect(got.quote).not.toContain('LEAK')
    expect(got.prefix).toBe('Choose the ')
    expect(got.suffix).toBe(' $99 a year')
  })

  it('finds the second of two identical quotes by its context, after a restyle', () => {
    page('<p>Monthly: Annual plan is off.</p><p>Choose the Annual plan for $99</p>')
    const second = document.querySelectorAll('p')[1].firstChild
    const saved = mod.captureFromRange(selectText(second, 11, 22))
    expect(saved.quote).toBe('Annual plan')

    // Leo restyles the page: new tags around the same words.
    page('<section><div><span>Monthly:</span> <em>Annual plan</em> is off.</div><div><strong>Choose</strong> the <span class="x">Annual plan</span> for $99</div></section>')
    const T = mod.buildText()
    const span = mod.locate(T, saved.quote, saved.prefix, saved.suffix)
    const before = T.text.slice(0, span[0])
    expect(before).toContain('Choose the')
    expect(mod.rangeFor(T, span).startContainer.parentElement.className).toBe('x')
  })

  it('reports nothing for a quote that is gone', () => {
    page('<p>Choose the Yearly plan</p>')
    expect(mod.locate(mod.buildText(), 'Annual plan', 'Choose the ', '')).toBeNull()
  })

  it('describes a clicked element and keeps its CSS path', () => {
    page('<main><button>Sign up</button><button id="go">Go</button></main>')
    const info = mod.pickInfo(document.querySelector('button'))
    expect(info.label).toBe('button "Sign up"')
    expect(info.selector).toBe('body > main:nth-of-type(1) > button:nth-of-type(1)')
    expect(info.quote).toBe('Sign up')
    expect(mod.cssPath(document.getElementById('go'))).toBe('#go')
  })

  it('moves a colliding pin 32px left so pins never stack', () => {
    const rect = { right: 200, top: 100 }
    const pins = mod.placePins([{ id: 1, rect }, { id: 2, rect }, { id: 3, rect }], { viewportWidth: 1000 })
    expect(pins[1].left).toBe(pins[0].left - 32)
    expect(pins[2].left).toBe(pins[0].left - 64)
    expect(pins[0].top).toBe(pins[1].top)
  })
})

describe('on the page', () => {
  const PAGE = '<main><h1>Plans</h1><p>Choose the Annual plan for $99</p><p>Other text</p></main>'

  it('does nothing for a signed-out visitor', async () => {
    window.llamapressConfig = { pageCommentsEnabled: false }
    page(PAGE)
    bubble()
    global.fetch = vi.fn()
    await mod.init()
    expect(global.fetch).not.toHaveBeenCalled()
    expect(document.querySelector('llama-comments')).toBeNull()
    expect(document.querySelector('[data-llama-pc]')).toBeNull()
  })

  it('is OFF by default: no pins, just a count badge on the bubble', async () => {
    page(PAGE)
    const b = bubble()
    mockApi([comment(1), comment(2, { quote: 'Other text' })])
    await mod.init()

    const shadow = document.querySelector('llama-comments').shadowRoot
    expect(shadow.querySelectorAll('.pin').length).toBe(0)
    const badge = b.querySelector('[data-llama-pc="badge"]')
    expect(badge.textContent).toBe('2')
    expect(badge.hidden).toBe(false)
    const sw = b.querySelector('[role="switch"]')
    expect(sw.getAttribute('aria-checked')).toBe('false')
  })

  it('shows initial pins when switched on, remembers it, and never touches page text', async () => {
    page(PAGE)
    const b = bubble()
    mockApi([comment(1), comment(2, { quote: 'Other text', author: { id: 3, name: 'Zoe', initial: 'Z' } })])
    const main = document.querySelector('main')
    const before = main.innerHTML
    await mod.init()

    b.querySelector('[role="switch"]').click()
    const shadow = document.querySelector('llama-comments').shadowRoot
    const pins = Array.from(shadow.querySelectorAll('.pin'))
    expect(pins.map((p) => p.textContent)).toEqual(['A', 'Z'])
    expect(pins[0].getAttribute('aria-label')).toBe('Comment by Ana Lima: Comment 1')
    expect(b.querySelector('[role="switch"]').getAttribute('aria-checked')).toBe('true')
    expect(mod.loadShow()).toBe(true)

    pins[0].click()
    expect(shadow.querySelector('[data-card="thread"]')).not.toBeNull()
    expect(main.innerHTML).toBe(before)
    expect(document.querySelectorAll('main mark, main span').length).toBe(0)
    expect(document.querySelectorAll('llama-comments').length).toBe(1)

    b.querySelector('[role="switch"]').click()
    expect(shadow.querySelectorAll('.pin, .card, .box').length).toBe(0)
  })

  it('renders names, quotes and bodies as text, never as HTML', async () => {
    page('<main><p>&lt;img src=x onerror=alert(1)&gt; here</p></main>')
    bubble()
    const evil = '<img src=x onerror=alert(1)>'
    mockApi([comment(1, { quote: `${evil} here`, body: evil, author: { id: 9, name: evil, initial: '<' } })])
    window.localStorage.setItem('llamapress.pageComments.show:' + window.location.host, '1')
    await mod.init()

    const shadow = document.querySelector('llama-comments').shadowRoot
    shadow.querySelector('.pin').click()
    const card = shadow.querySelector('[data-card="thread"]')
    expect(card.querySelector('img')).toBeNull()
    expect(card.textContent).toContain(evil)
  })

  it('lists a comment whose text was rewritten under "Text changed since this comment" and reports it detached', async () => {
    page(PAGE)
    bubble()
    const calls = mockApi([comment(1), comment(5, { quote: 'Gone forever' })])
    await mod.init()
    mod._state().loadedAt = 0
    mod.anchorAll()

    const patch = calls.find((c) => c.method === 'PATCH')
    expect(patch.url).toBe('/llama_bot/page_comments/5')
    expect(patch.body).toEqual({ page_comment: { anchor_state: 'detached' } })

    document.querySelector('[data-llama-pc="list"]').click()
    const list = document.querySelector('llama-comments').shadowRoot.querySelector('[data-list]')
    expect(list.textContent).toContain('Text changed since this comment')
    const detached = list.querySelector('[data-detached]')
    expect(detached.textContent).toContain('Gone forever')
    expect(detached.querySelector('[data-act="reattach"]')).not.toBeNull()
  })

  it('tears down before Turbo caches the page and comes back once', async () => {
    page(PAGE)
    bubble()
    mockApi([comment(1)])
    await mod.init()
    expect(document.querySelectorAll('llama-comments').length).toBe(1)

    document.dispatchEvent(new Event('turbo:before-cache'))
    expect(document.querySelector('llama-comments')).toBeNull()
    expect(document.querySelector('[data-llama-pc]')).toBeNull()
    expect(document.querySelector('style[data-lp-injected]')).toBeNull()

    await mod.init()
    await mod.init()
    expect(document.querySelectorAll('llama-comments').length).toBe(1)
    expect(document.querySelectorAll('[data-llama-pc="controls"]').length).toBe(1)
  })

  it('hands Leo the open comments, capped, without our markup in the page HTML', async () => {
    page(PAGE)
    bubble()
    const many = Array.from({ length: 25 }, (_, i) => comment(i + 1, { body: 'x'.repeat(400) }))
    mockApi(many)
    await mod.init()

    const leo = mod.forLeo()
    expect(leo.length).toBe(20)
    expect(leo[0]).toMatchObject({ id: 1, quote: 'Annual plan', author: 'Ana Lima', state: 'attached' })
    expect(leo[0].body.length).toBe(300)

    const html = mod.stripInjectedMarkup(document.documentElement.outerHTML)
    expect(html).not.toContain('<llama-comments')
    expect(html).not.toContain('data-lp-injected')
  })

  it('saves a selection comment through the API with its anchor', async () => {
    page(PAGE)
    bubble()
    const calls = mockApi([])
    await mod.init()
    const p = document.querySelectorAll('p')[0].firstChild
    const info = mod.captureFromRange(selectText(p, 11, 22))
    // Drive the compose card the way the chip does.
    window.getSelection().removeAllRanges()
    window.getSelection().addRange(selectText(p, 11, 22))
    document.dispatchEvent(new Event('mouseup'))
    await new Promise((r) => setTimeout(r, 200))
    const shadow = document.querySelector('llama-comments').shadowRoot
    const chip = shadow.querySelector('.chip')
    expect(chip).not.toBeNull()
    chip.click()
    const ta = shadow.querySelector('[data-compose]')
    ta.value = 'Price is wrong'
    shadow.querySelector('[data-act="save"]').click()
    await new Promise((r) => setTimeout(r, 0))

    const post = calls.find((c) => c.method === 'POST')
    expect(post.body.page_comment).toMatchObject({
      body: 'Price is wrong', page_path: '/pricing', anchor_quote: info.quote,
      anchor_prefix: 'Plans Choose the ', anchor_suffix: ' for $99 Other text'
    })
  })
})
