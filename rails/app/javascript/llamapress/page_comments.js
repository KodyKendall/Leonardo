// Page comments (LP-57): signed-in users highlight text, or click any element in
// Comment Mode, and leave a comment pinned to it. Each comment is a feedback item
// (UserFeedback type "page_comment") so it also lands in /llama_bot/feedback.
//
// Rules this file keeps:
// - The page's own DOM is never changed. Pins, chip, cards, list, hover outline and
//   highlight boxes all live in ONE shadow root on <llama-comments data-lp-injected>.
//   The only light-DOM additions are that host and a <style data-lp-injected> for the
//   ::highlight() colour, and both are removed on turbo:before-cache.
// - Hidden by default. "Show comments" (in the feedback bubble) is remembered per host.
//   With it off the page looks unchanged; the bubble only shows an open-comment count.
// - Anchors are a text quote + 40 chars of context either side, taken from the page's
//   visible text nodes (never Range#toString, which includes <script> text), with the
//   clicked element's CSS path as the fallback. Not found either way = "detached",
//   listed under "Text changed since this comment", never deleted.
// - Everything a person typed is put on screen with textContent, never innerHTML.
//
// Ported from Mother Leo Lite's artifact bridge (pins, pick, cssPath, context) and Leo
// Insight's text anchoring (buildText, posOf, locate); <mark> wrapping and the
// postMessage layer were left behind.

const CTX = 40
const QUOTE_MAX = 2000
const PIN = 28
const PIN_SHIFT = 32
const REPAINT_MS = 120
// Lazy Turbo Frames may still be arriving; a comment is only REPORTED detached after this.
const DETACH_GRACE_MS = 1500
const LEO_MAX = 20
const LEO_BODY_MAX = 300
const STORE_PREFIX = 'llamapress.pageComments.show:'
const HOST_TAG = 'llama-comments'
const HIGHLIGHT_NAME = 'llama-comment'
const SKIP_TAGS_TEXT = /^(SCRIPT|STYLE|NOSCRIPT|TEXTAREA|TEMPLATE|SELECT|OPTION|INPUT)$/
// Our own UI and anything an app marks as not-the-page.
const SKIP_SELECTOR = '[data-lp-injected], [data-llama-no-comments], #llamapress-feedback-bubble, ' + HOST_TAG
// A block boundary reads as a space, as it does in a selection, so a quote across two
// table cells still matches.
const BLOCK = 'p,div,td,th,li,tr,table,section,article,header,footer,main,nav,aside,blockquote,pre,ul,ol,dl,dt,dd,h1,h2,h3,h4,h5,h6,figure,figcaption,details,summary,form,label'

// ---------------------------------------------------------------------------
// Pure helpers (exported for tests)
// ---------------------------------------------------------------------------

export function norm(s) { return String(s || '').replace(/\s+/g, ' ').trim() }

export function normalizePath(raw) {
  let p = String(raw || '').split(/[?#]/)[0]
  if (!p.startsWith('/')) p = '/' + p
  p = p.replace(/\/+$/, '')
  return p || '/'
}

// Visible text nodes under root, in document order. Skipped subtrees (script, our own
// UI, the bubble) are pruned whole. A plain walk rather than a TreeWalker: cheaper to
// prune, and it behaves the same in every DOM implementation.
function textNodes(root) {
  const out = []
  const stack = [root]
  while (stack.length) {
    const n = stack.pop()
    if (n.nodeType === 3) { out.push(n); continue }
    if (n.nodeType !== 1 && n.nodeType !== 11) continue
    if (n.nodeType === 1 && n !== root && (SKIP_TAGS_TEXT.test(n.nodeName.toUpperCase()) || n.matches(SKIP_SELECTOR))) continue
    for (let c = n.lastChild; c; c = c.previousSibling) stack.push(c)
  }
  return out
}

// The page's visible text as one whitespace-collapsed string. Each text node keeps a
// map from positions in that string back to its own offsets.
export function buildText(body = document.body) {
  const segs = []
  const out = []
  let lastSpace = true
  let lastBlock = null
  if (!body) return { text: '', segs }
  for (const n of textNodes(body)) {
    const blk = n.parentNode.closest(BLOCK)
    if (blk !== lastBlock && !lastSpace) { out.push(' '); lastSpace = true }
    lastBlock = blk
    const data = n.data
    const map = []
    const start = out.length
    for (let i = 0; i < data.length; i++) {
      const sp = /\s/.test(data[i])
      if (sp && lastSpace) continue
      out.push(sp ? ' ' : data[i]); map.push(i); lastSpace = sp
    }
    segs.push({ node: n, start, end: out.length, map })
  }
  return { text: out.join(''), segs }
}

// Position in T.text of a DOM boundary point (a Range start or end).
export function posOf(T, container, offset) {
  if (container.nodeType === 3) {
    for (const s of T.segs) {
      if (s.node !== container) continue
      let idx = 0
      while (idx < s.map.length && s.map[idx] < offset) idx++
      return s.start + idx
    }
  }
  // An element boundary, or a skipped text node: the end of the last indexed text
  // node that comes before the point.
  const probe = document.createRange()
  try {
    probe.setStart(container, offset)
  } catch (_) { return -1 }
  let best = 0
  for (const s of T.segs) {
    if (probe.comparePoint(s.node, 0) < 0) best = s.end
    else break
  }
  return best
}

function commonTail(a, b) {
  let n = 0
  while (n < a.length && n < b.length && a[a.length - 1 - n] === b[b.length - 1 - n]) n++
  return n
}
function commonHead(a, b) {
  let n = 0
  while (n < a.length && n < b.length && a[n] === b[n]) n++
  return n
}

// Every copy of the quote, scored by how much of the saved context matches; the best
// one wins. Returns [start, end) in T.text, or null.
export function locate(T, quote, prefix, suffix) {
  const q = norm(quote)
  if (!q) return null
  const p = norm(prefix) ? String(prefix).replace(/\s+/g, ' ') : ''
  const x = norm(suffix) ? String(suffix).replace(/\s+/g, ' ') : ''
  let best = null
  let bestScore = -1
  let at = T.text.indexOf(q)
  while (at !== -1) {
    const before = T.text.slice(Math.max(0, at - CTX), at)
    const after = T.text.slice(at + q.length, at + q.length + CTX)
    const score = commonTail(before, p) + commonHead(after, x)
    if (score > bestScore) { bestScore = score; best = [at, at + q.length] }
    at = T.text.indexOf(q, at + 1)
  }
  return best
}

export function contextAround(T, start, end) {
  return {
    prefix: T.text.slice(Math.max(0, start - CTX), start),
    suffix: T.text.slice(end, end + CTX)
  }
}

// A DOM Range over [start, end) of T.text.
export function rangeFor(T, span) {
  let a = null
  let z = null
  for (const s of T.segs) {
    if (!a && span[0] < s.end && span[0] >= s.start) a = [s.node, s.map[span[0] - s.start]]
    if (span[1] - 1 >= s.start && span[1] - 1 < s.end) { z = [s.node, s.map[span[1] - 1 - s.start] + 1]; break }
  }
  if (!a || !z) return null
  const r = document.createRange()
  r.setStart(a[0], a[1])
  r.setEnd(z[0], z[1])
  return r
}

// The anchor for a text selection, read from text nodes only.
export function captureFromRange(range, T = buildText()) {
  const a = posOf(T, range.startContainer, range.startOffset)
  const b = posOf(T, range.endContainer, range.endOffset)
  if (a < 0 || b <= a) return null
  let start = a
  let end = b
  while (start < end && T.text[start] === ' ') start++
  while (end > start && T.text[end - 1] === ' ') end--
  if (end <= start || end - start > QUOTE_MAX) return null
  const quote = T.text.slice(start, end)
  let anc = range.commonAncestorContainer
  if (anc && anc.nodeType === 3) anc = anc.parentElement
  return { quote, ...contextAround(T, start, end), selector: anc ? cssPath(anc) : '', label: describe(anc, quote) }
}

// A short CSS path to an element, so a comment on a chart or image finds it again.
export function cssPath(el) {
  const parts = []
  for (let n = el; n && n.nodeType === 1 && n !== document.body && n !== document.documentElement; n = n.parentElement) {
    if (n.id && /^[A-Za-z][\w-]*$/.test(n.id)) { parts.unshift('#' + n.id); break }
    const tag = n.nodeName.toLowerCase()
    let i = 1
    let sib = n
    while ((sib = sib.previousElementSibling)) { if (sib.nodeName === n.nodeName) i++ }
    parts.unshift(`${tag}:nth-of-type(${i})`)
    if (parts.length > 8) break
  }
  if (!parts.length) return ''
  return (parts[0].charAt(0) === '#' ? '' : 'body > ') + parts.join(' > ')
}

function short(t, n) {
  t = norm(t)
  return t.length > n ? t.slice(0, n - 1) + '…' : t
}

function kindOf(el) {
  const tg = el.nodeName.toLowerCase()
  if (/^h[1-6]$/.test(tg)) return 'heading'
  if (tg === 'a') return 'link'
  if (tg === 'button' || el.getAttribute('role') === 'button') return 'button'
  if (tg === 'td' || tg === 'th') return 'table cell'
  if (tg === 'canvas' || tg === 'svg') return 'chart'
  if (tg === 'img' || tg === 'picture') return 'image'
  return 'text'
}

function describe(el, text) {
  if (!el || el.nodeType !== 1) return ''
  const visual = el.closest('canvas,svg,img,video,picture,iframe')
  const target = visual || el.closest('h1,h2,h3,h4,h5,h6,a,button,td,th') || el
  const name = target.getAttribute('aria-label') || target.getAttribute('alt') || target.getAttribute('title') || text || target.textContent
  const s = short(name, 40)
  return s ? `${kindOf(target)} "${s}"` : kindOf(target)
}

// The anchor for an element clicked in Comment Mode.
export function pickInfo(el, T = buildText()) {
  const visual = el.closest('canvas,svg,img,video,picture,iframe')
  const target = visual || el
  const out = { quote: '', prefix: '', suffix: '', selector: cssPath(target), label: describe(target) }
  if (visual || target === document.body || target === document.documentElement) {
    if (!visual) out.label = 'whole page'
    return out
  }
  const own = T.segs.filter((s) => target.contains(s.node) && s.end > s.start)
  if (!own.length) return out
  const start = own[0].start
  const end = Math.min(own[own.length - 1].end, start + 300)
  let a = start
  let b = end
  while (a < b && T.text[a] === ' ') a++
  while (b > a && T.text[b - 1] === ' ') b--
  if (b > a) Object.assign(out, { quote: T.text.slice(a, b) }, contextAround(T, a, b))
  return out
}

// Pin positions in document coordinates. A pin that would land on another one moves
// left by PIN_SHIFT until it is clear, so pins never stack.
export function placePins(items, { viewportWidth, scrollX = 0, scrollY = 0 }) {
  const taken = new Set()
  return items.map(({ id, rect }) => {
    let left = Math.min(Math.max(rect.right + 4, 4), viewportWidth - PIN - 6) + scrollX
    const top = Math.max(rect.top - PIN + 2, 2) + scrollY
    const key = (l) => `${Math.round(l / PIN_SHIFT)}:${Math.round(top / PIN_SHIFT)}`
    let guard = 0
    while (taken.has(key(left)) && guard++ < 50) left -= PIN_SHIFT
    taken.add(key(left))
    return { id, left, top }
  })
}

function initialOf(name) { return (String(name || '').trim()[0] || '?').toUpperCase() }

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

const state = {
  host: null, shadow: null, styleTag: null,
  comments: [], me: null, includeResolved: false,
  anchors: new Map(), // id -> { range?, el? } for attached comments
  show: false, mode: 'idle', // idle | pick | reattach
  reattachId: null, pendingSel: null, activeId: null, card: null,
  listOpen: false, lastFocus: null,
  observers: [], timers: {}, reported: new Map(), page: null,
  listenersBound: false, loadedAt: 0
}

function config() { return window.llamapressConfig || {} }
export function isEnabled() { return Boolean(config().pageCommentsEnabled) }
function apiBase() { return config().pageCommentsUrl || '/llama_bot/page_comments' }
function storeKey() { return STORE_PREFIX + window.location.host }

export function loadShow() {
  try { return window.localStorage.getItem(storeKey()) === '1' } catch (_) { return false }
}
function saveShow(on) {
  try { window.localStorage.setItem(storeKey(), on ? '1' : '0') } catch (_) { /* private mode */ }
}

function csrf() {
  const m = document.querySelector('meta[name="csrf-token"]')
  return m ? m.getAttribute('content') : ''
}

async function api(method, path, body) {
  const res = await fetch(apiBase() + path, {
    method,
    credentials: 'same-origin',
    headers: { Accept: 'application/json', 'Content-Type': 'application/json', 'X-CSRF-Token': csrf() },
    body: body ? JSON.stringify(body) : undefined
  })
  let data = null
  try { data = await res.json() } catch (_) { data = null }
  if (!res.ok) {
    const err = new Error((data && (data.error || data.message || (data.errors || []).join(', '))) || `Status ${res.status}`)
    err.status = res.status
    throw err
  }
  return data
}

function openComments() { return state.comments.filter((c) => !c.resolved) }
function byId(id) { return state.comments.find((c) => String(c.id) === String(id)) }

// ---------------------------------------------------------------------------
// Shadow host
// ---------------------------------------------------------------------------

const SHADOW_CSS = `
:host { all: initial; }
* { box-sizing: border-box; }
.layer { position: absolute; left: 0; top: 0; width: 0; height: 0; z-index: 2147483000; font: 14px/1.4 system-ui, -apple-system, "Segoe UI", sans-serif; color: #111827; }
.pin { all: initial; position: absolute; width: 28px; height: 28px; box-sizing: border-box; border-radius: 50% 50% 50% 4px;
  background: #7c3aed; color: #fff; font: 600 12px/28px system-ui, -apple-system, sans-serif; text-align: center; cursor: pointer;
  box-shadow: 0 0 0 2px #fff, 0 3px 10px rgba(15,23,42,.35); transition: transform .12s ease; }
.pin:hover, .pin:focus-visible { transform: scale(1.12); }
.pin:focus-visible { outline: 3px solid #1e1b4b; outline-offset: 2px; }
.pin.on { background: #6d28d9; box-shadow: 0 0 0 2.5px #fff, 0 0 0 5px #6d28d9, 0 6px 16px rgba(0,0,0,.4); transform: scale(1.12); }
.box { position: absolute; pointer-events: none; border-radius: 3px; }
.box.hover { outline: 2px solid rgba(124,58,237,.85); outline-offset: 2px; }
.box.hl { background: rgba(250,204,21,.35); outline: 2px solid #a16207; }
.chip { position: absolute; display: inline-flex; align-items: center; gap: 6px; padding: 6px 12px; min-height: 36px; border: 0; border-radius: 999px;
  background: #6d28d9; color: #fff; font: 600 13px system-ui, sans-serif; cursor: pointer; box-shadow: 0 4px 14px rgba(0,0,0,.25); }
.modebar { position: fixed; top: 12px; left: 50%; transform: translateX(-50%); cursor: default; }
.modebar .btn { min-height: 28px; padding: 2px 10px; }
.chip:focus-visible, .btn:focus-visible, textarea:focus-visible, .link:focus-visible, .switch:focus-visible { outline: 3px solid #1e1b4b; outline-offset: 2px; }
.card, .list { position: absolute; width: min(340px, calc(100vw - 24px)); background: #fff; color: #111827; border: 1px solid #d1d5db; border-radius: 12px;
  box-shadow: 0 12px 32px rgba(15,23,42,.25); padding: 12px; }
.list { position: fixed; right: 16px; bottom: 84px; max-height: min(70vh, 560px); overflow: auto; }
@media (max-width: 640px) {
  .list, .card.sheet { position: fixed; left: 0; right: 0; bottom: 0; top: auto; width: 100%; max-height: 75vh; overflow: auto; border-radius: 16px 16px 0 0; }
}
.crumb { font-size: 12px; color: #4b5563; margin: 0 0 8px; overflow-wrap: anywhere; }
.quote { font-style: italic; color: #4b5563; border-left: 3px solid #c4b5fd; padding-left: 8px; margin: 0 0 8px; overflow-wrap: anywhere; }
.quote.gone { color: #6b7280; text-decoration: line-through; }
.who { display: flex; align-items: center; gap: 8px; font-weight: 600; font-size: 13px; }
.av { width: 24px; height: 24px; border-radius: 50%; background: #7c3aed; color: #fff; display: inline-flex; align-items: center; justify-content: center; font-size: 11px; flex: none; }
.when { font-weight: 400; color: #4b5563; font-size: 12px; }
.body { margin: 4px 0 10px 32px; white-space: pre-wrap; overflow-wrap: anywhere; }
.reply { margin-left: 16px; }
textarea { width: 100%; min-height: 64px; resize: vertical; border: 1px solid #9ca3af; border-radius: 8px; padding: 8px; font: inherit; color: inherit; }
.row { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; margin-top: 8px; }
.btn { border: 1px solid #9ca3af; background: #fff; color: #111827; border-radius: 8px; padding: 6px 12px; min-height: 36px; font: 600 13px system-ui, sans-serif; cursor: pointer; }
.btn.primary { background: #6d28d9; border-color: #6d28d9; color: #fff; }
.btn.danger { color: #b91c1c; border-color: #fca5a5; }
.btn[disabled] { opacity: .6; cursor: default; }
.link { all: unset; color: #5b21b6; text-decoration: underline; cursor: pointer; font-size: 13px; }
h2 { font-size: 15px; margin: 0 0 8px; }
h3 { font-size: 13px; margin: 14px 0 6px; color: #374151; }
ul { list-style: none; padding: 0; margin: 0; }
li.item { border-top: 1px solid #e5e7eb; padding: 8px 0; }
.empty { color: #4b5563; font-size: 13px; }
.sr { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
@media (prefers-reduced-motion: reduce) { .pin { transition: none; } }
`

function ensureHost() {
  if (state.host && state.host.isConnected) return state.shadow
  document.querySelectorAll(HOST_TAG).forEach((n) => n.remove())
  const host = document.createElement(HOST_TAG)
  host.setAttribute('data-lp-injected', '')
  host.setAttribute('style', 'position:absolute;left:0;top:0;width:0;height:0;z-index:2147483000;')
  const shadow = host.attachShadow({ mode: 'open' })
  const style = document.createElement('style')
  style.textContent = SHADOW_CSS
  shadow.appendChild(style)
  for (const cls of ['layer pins', 'layer boxes', 'layer ui']) {
    const d = document.createElement('div')
    d.className = cls
    shadow.appendChild(d)
  }
  const live = document.createElement('div')
  live.className = 'sr'
  live.setAttribute('role', 'status')
  live.setAttribute('aria-live', 'polite')
  shadow.appendChild(live)
  shadow.addEventListener('click', onShadowClick)
  shadow.addEventListener('keydown', onShadowKeydown)
  // Keep the page's text selection when a chip or button is pressed.
  shadow.addEventListener('mousedown', (e) => { if (e.target.closest && e.target.closest('.chip')) e.preventDefault() })
  document.body.appendChild(host)
  state.host = host
  state.shadow = shadow
  return shadow
}

function layer(name) { const sh = ensureHost(); return sh.querySelector('.layer.' + name) }

function announce(msg) {
  const sh = ensureHost()
  const live = sh.querySelector('[role="status"]')
  live.textContent = ''
  setTimeout(() => { live.textContent = msg }, 30)
}

function el(tag, attrs = {}, text) {
  const n = document.createElement(tag)
  for (const [k, v] of Object.entries(attrs)) {
    if (v === false || v == null) continue
    if (k === 'className') n.className = v
    else n.setAttribute(k, v === true ? '' : v)
  }
  if (text != null) n.textContent = text
  return n
}

// ---------------------------------------------------------------------------
// Anchoring
// ---------------------------------------------------------------------------

function findAnchor(c, T) {
  if (c.quote) {
    const span = locate(T, c.quote, c.prefix, c.suffix)
    if (span) {
      const range = rangeFor(T, span)
      if (range) return { range, at: span[0] }
    }
  }
  if (c.selector) {
    let node = null
    try { node = document.querySelector(c.selector) } catch (_) { node = null }
    if (node && !node.closest(SKIP_SELECTOR)) return { el: node, at: posOfElement(T, node) }
  }
  if (!c.quote && !c.selector) return { el: document.body, at: -1 }
  return null
}

function posOfElement(T, node) {
  const s = T.segs.find((seg) => node.contains(seg.node))
  return s ? s.start : 0
}

// Find every comment on the page. A comment whose state changed is reported once per
// page view: detached when lost, attached again when an edit is undone.
export function anchorAll() {
  const T = buildText()
  state.anchors.clear()
  for (const c of state.comments) {
    if (c.resolved) continue
    const found = findAnchor(c, T)
    if (found) state.anchors.set(String(c.id), found)
    const now = found ? 'attached' : 'detached'
    if (now === 'detached' && Date.now() - state.loadedAt < DETACH_GRACE_MS) continue
    if (now !== c.state && state.reported.get(String(c.id)) !== now) {
      state.reported.set(String(c.id), now)
      c.state = now
      api('PATCH', `/${c.id}`, { page_comment: { anchor_state: now } }).catch(() => {})
    }
  }
}

function rectOf(anchor) {
  if (anchor.range) {
    const rects = anchor.range.getClientRects()
    return rects.length ? rects[0] : anchor.range.getBoundingClientRect()
  }
  return anchor.el.getBoundingClientRect()
}

function attachedInPageOrder() {
  return openComments()
    .filter((c) => state.anchors.has(String(c.id)))
    .sort((a, b) => state.anchors.get(String(a.id)).at - state.anchors.get(String(b.id)).at)
}

// ---------------------------------------------------------------------------
// Painting
// ---------------------------------------------------------------------------

function paintPins() {
  const pins = layer('pins')
  pins.replaceChildren()
  if (!state.show) return
  const items = attachedInPageOrder().map((c) => ({ id: c.id, rect: rectOf(state.anchors.get(String(c.id))) }))
  const placed = placePins(items, {
    viewportWidth: document.documentElement.clientWidth || window.innerWidth,
    scrollX: window.scrollX, scrollY: window.scrollY
  })
  for (const p of placed) {
    const c = byId(p.id)
    const pin = el('button', {
      type: 'button', className: 'pin' + (String(p.id) === String(state.activeId) ? ' on' : ''),
      'data-pin': p.id, 'aria-label': `Comment by ${c.author.name}: ${short(c.body, 60)}`,
      'aria-expanded': String(String(p.id) === String(state.activeId))
    }, c.author.initial || initialOf(c.author.name))
    pin.style.left = p.left + 'px'
    pin.style.top = p.top + 'px'
    pins.appendChild(pin)
  }
}

function clearHighlight() {
  try { if (window.CSS && CSS.highlights) CSS.highlights.delete(HIGHLIGHT_NAME) } catch (_) { /* old browser */ }
  if (state.shadow) state.shadow.querySelectorAll('.box.hl').forEach((n) => n.remove())
}

function ensureHighlightStyle() {
  if (state.styleTag && state.styleTag.isConnected) return
  const s = document.createElement('style')
  s.setAttribute('data-lp-injected', '')
  s.textContent = `::highlight(${HIGHLIGHT_NAME}) { background-color: rgba(250, 204, 21, .45); text-decoration: underline 2px #a16207; }`
  document.head.appendChild(s)
  state.styleTag = s
}

// The target is highlighted only while its thread is open, and never by touching the
// page's text nodes: the CSS Custom Highlight API where there is one, boxes otherwise.
function highlight(anchor) {
  clearHighlight()
  if (!anchor) return
  if (anchor.range && window.CSS && CSS.highlights && typeof window.Highlight === 'function') {
    ensureHighlightStyle()
    CSS.highlights.set(HIGHLIGHT_NAME, new window.Highlight(anchor.range))
    return
  }
  const rects = anchor.range ? Array.from(anchor.range.getClientRects()) : [anchor.el.getBoundingClientRect()]
  const boxes = layer('boxes')
  for (const r of rects) {
    const b = el('div', { className: 'box hl' })
    Object.assign(b.style, { left: r.left + window.scrollX + 'px', top: r.top + window.scrollY + 'px', width: r.width + 'px', height: r.height + 'px' })
    boxes.appendChild(b)
  }
}

function repaint() {
  anchorAll()
  paintPins()
  if (state.activeId) {
    const a = state.anchors.get(String(state.activeId))
    highlight(a)
    if (state.card) positionCard(state.card, a)
  }
  if (state.listOpen) renderList()
  updateBubbleControls()
}

function repaintSoon() {
  clearTimeout(state.timers.repaint)
  state.timers.repaint = setTimeout(repaint, REPAINT_MS)
}

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------

function closeCard({ restoreFocus = true } = {}) {
  if (state.card) state.card.remove()
  state.card = null
  state.activeId = null
  clearHighlight()
  paintPins()
  if (restoreFocus && state.lastFocus && state.lastFocus.isConnected) {
    try { state.lastFocus.focus() } catch (_) { /* gone */ }
  }
  state.lastFocus = null
}

function positionCard(card, anchor) {
  const narrow = window.matchMedia && window.matchMedia('(max-width: 640px)').matches
  card.classList.toggle('sheet', Boolean(narrow || !anchor))
  if (narrow || !anchor) { card.style.left = ''; card.style.top = ''; return }
  const r = rectOf(anchor)
  const vw = document.documentElement.clientWidth || window.innerWidth
  const left = Math.max(8, Math.min(r.right + 12, vw - 352)) + window.scrollX
  card.style.left = left + 'px'
  card.style.top = Math.max(8, r.top) + window.scrollY + 'px'
}

function mountCard(card, anchor) {
  if (state.card) state.card.remove()
  state.lastFocus = state.lastFocus || document.activeElement
  card.setAttribute('role', 'dialog')
  card.setAttribute('aria-modal', 'true')
  layer('ui').appendChild(card)
  state.card = card
  positionCard(card, anchor)
  const first = card.querySelector('textarea, button')
  if (first) first.focus()
}

function crumbFor(anchor) {
  const page = norm(document.title) || window.location.pathname
  return anchor && anchor.label ? `${page} › ${anchor.label}` : page
}

function openCompose(anchor) {
  hideChip()
  const card = el('div', { className: 'card', 'aria-label': 'Add a comment', 'data-card': 'compose' })
  card.appendChild(el('p', { className: 'crumb' }, crumbFor(anchor)))
  if (anchor.quote) card.appendChild(el('p', { className: 'quote' }, short(anchor.quote, 200)))
  const ta = el('textarea', { 'aria-label': 'Add a comment', placeholder: 'Add a comment', 'data-compose': '' })
  card.appendChild(ta)
  const row = el('div', { className: 'row' })
  row.appendChild(el('button', { type: 'button', className: 'btn primary', 'data-act': 'save' }, 'Comment'))
  row.appendChild(el('button', { type: 'button', className: 'btn', 'data-act': 'cancel' }, 'Cancel'))
  card.appendChild(row)
  card._anchor = anchor
  state.activeId = null
  mountCard(card, anchor.rect ? { el: { getBoundingClientRect: () => anchor.rect } } : null)
}

function when(iso) {
  if (!iso) return ''
  const d = new Date(iso)
  return isNaN(d) ? '' : d.toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })
}

function personRow(author, iso) {
  const row = el('div', { className: 'who' })
  row.appendChild(el('span', { className: 'av', 'aria-hidden': 'true' }, author.initial || initialOf(author.name)))
  row.appendChild(el('span', {}, author.name))
  row.appendChild(el('span', { className: 'when' }, when(iso)))
  return row
}

function openThread(id) {
  const c = byId(id)
  if (!c) return
  hideChip()
  state.activeId = c.id
  const anchor = state.anchors.get(String(c.id))
  const card = el('div', { className: 'card', 'aria-label': `Comment by ${c.author.name}`, 'data-card': 'thread', 'data-id': c.id })
  if (c.label || c.quote) card.appendChild(el('p', { className: 'crumb' }, crumbFor({ label: c.label })))
  if (c.quote) card.appendChild(el('p', { className: 'quote' + (anchor ? '' : ' gone') }, short(c.quote, 200)))
  card.appendChild(personRow(c.author, c.created_at))
  card.appendChild(el('p', { className: 'body' }, c.body))
  for (const r of c.replies || []) {
    const wrap = el('div', { className: 'reply' })
    wrap.appendChild(personRow(r.author, r.created_at))
    wrap.appendChild(el('p', { className: 'body' }, r.body))
    card.appendChild(wrap)
  }
  if (!c.resolved) card.appendChild(el('textarea', { 'aria-label': 'Reply', placeholder: 'Reply', 'data-reply': '' }))
  const row = el('div', { className: 'row' })
  if (!c.resolved) row.appendChild(el('button', { type: 'button', className: 'btn primary', 'data-act': 'reply' }, 'Reply'))
  row.appendChild(el('button', { type: 'button', className: 'btn', 'data-act': c.resolved ? 'reopen' : 'resolve' }, c.resolved ? 'Reopen' : 'Resolve'))
  if (!anchor && !c.resolved) row.appendChild(el('button', { type: 'button', className: 'btn', 'data-act': 'reattach' }, 'Re-attach'))
  if (c.can_delete) row.appendChild(el('button', { type: 'button', className: 'btn danger', 'data-act': 'delete' }, 'Delete'))
  row.appendChild(el('button', { type: 'button', className: 'btn', 'data-act': 'close' }, 'Close'))
  card.appendChild(row)
  mountCard(card, anchor)
  paintPins()
  highlight(anchor)
  if (anchor) {
    const r = rectOf(anchor)
    if (r.top < 0 || r.bottom > window.innerHeight) {
      const reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches
      window.scrollTo({ top: Math.max(0, r.top + window.scrollY - 120), behavior: reduce ? 'auto' : 'smooth' })
      repaintSoon()
    }
  }
}

// ---------------------------------------------------------------------------
// All-comments list
// ---------------------------------------------------------------------------

function listItem(c, detached) {
  const li = el('li', { className: 'item' })
  if (c.quote || c.label) li.appendChild(el('p', { className: 'quote' + (detached ? ' gone' : '') }, short(c.quote || c.label, 120)))
  li.appendChild(personRow(c.author, c.created_at))
  li.appendChild(el('p', { className: 'body' }, short(c.body, 160)))
  const row = el('div', { className: 'row' })
  row.appendChild(el('button', { type: 'button', className: 'link', 'data-act': 'open', 'data-id': c.id }, 'Open thread'))
  if (detached) {
    row.appendChild(el('button', { type: 'button', className: 'btn', 'data-act': 'reattach', 'data-id': c.id }, 'Re-attach'))
    row.appendChild(el('button', { type: 'button', className: 'btn', 'data-act': 'resolve', 'data-id': c.id }, 'Resolve'))
  }
  li.appendChild(row)
  return li
}

function renderList() {
  let list = state.shadow && state.shadow.querySelector('.list')
  if (!state.listOpen) { if (list) list.remove(); return }
  if (!list) {
    list = el('div', { className: 'list', role: 'dialog', 'aria-label': 'Comments on this page', 'data-list': '' })
    layer('ui').appendChild(list)
  }
  list.replaceChildren()
  list.appendChild(el('h2', {}, 'Comments on this page'))
  const actions = el('div', { className: 'row' })
  actions.appendChild(el('button', { type: 'button', className: 'btn primary', 'data-act': 'add-selected' }, 'Add comment on selected text'))
  actions.appendChild(el('button', { type: 'button', className: 'btn', 'data-act': 'pick' }, 'Comment on an item'))
  actions.appendChild(el('button', { type: 'button', className: 'btn', 'data-act': 'close-list' }, 'Close'))
  list.appendChild(actions)

  const attached = attachedInPageOrder()
  const detached = openComments().filter((c) => !state.anchors.has(String(c.id)))
  const ul = el('ul')
  attached.forEach((c) => ul.appendChild(listItem(c, false)))
  list.appendChild(ul)
  if (!attached.length) list.appendChild(el('p', { className: 'empty' }, 'No open comments on this page.'))

  if (detached.length) {
    list.appendChild(el('h3', {}, 'Text changed since this comment'))
    const dl = el('ul', { 'data-detached': '' })
    detached.forEach((c) => dl.appendChild(listItem(c, true)))
    list.appendChild(dl)
  }

  const lab = el('label', { className: 'row' })
  const cb = el('input', { type: 'checkbox', 'data-act': 'toggle-resolved' })
  cb.checked = state.includeResolved
  lab.appendChild(cb)
  lab.appendChild(el('span', {}, 'Show resolved'))
  list.appendChild(lab)
  if (state.includeResolved) {
    const resolved = state.comments.filter((c) => c.resolved)
    if (resolved.length) {
      const rl = el('ul')
      resolved.forEach((c) => rl.appendChild(listItem(c, false)))
      list.appendChild(rl)
    }
  }
}

function openList() {
  state.lastFocus = state.lastFocus || document.activeElement
  state.listOpen = true
  renderList()
  const first = state.shadow.querySelector('.list button')
  if (first) first.focus()
}

function closeList() {
  state.listOpen = false
  renderList()
  if (state.lastFocus && state.lastFocus.isConnected) { try { state.lastFocus.focus() } catch (_) { /* gone */ } }
  state.lastFocus = null
}

// ---------------------------------------------------------------------------
// Selection chip and Comment Mode
// ---------------------------------------------------------------------------

function hideChip() {
  const chip = state.shadow && state.shadow.querySelector('.chip')
  if (chip) chip.remove()
}

function insideOurUi(node) {
  if (!node) return false
  const e = node.nodeType === 1 ? node : node.parentElement
  return Boolean(e && e.closest && e.closest(SKIP_SELECTOR + ', input, textarea, [contenteditable=""], [contenteditable="true"]'))
}

function currentSelection() {
  const sel = window.getSelection && window.getSelection()
  if (!sel || sel.isCollapsed || !sel.rangeCount) return null
  const range = sel.getRangeAt(0)
  if (insideOurUi(range.startContainer) || insideOurUi(range.endContainer)) return null
  const info = captureFromRange(range)
  if (!info) return null
  info.rect = range.getBoundingClientRect()
  return info
}

function showChip(info) {
  hideChip()
  const label = state.mode === 'reattach' ? 'Re-attach here' : 'Comment'
  const chip = el('button', { type: 'button', className: 'chip', 'data-act': 'chip', 'aria-label': state.mode === 'reattach' ? 'Re-attach the comment to the selected text' : 'Comment on the selected text' }, label)
  const vw = document.documentElement.clientWidth || window.innerWidth
  chip.style.left = Math.max(8, Math.min(info.rect.left, vw - 140)) + window.scrollX + 'px'
  chip.style.top = info.rect.bottom + 8 + window.scrollY + 'px'
  layer('ui').appendChild(chip)
}

function onSelectionSettled() {
  if (!isEnabled() || !state.host) return
  if (state.card || state.mode === 'pick') { hideChip(); return }
  const info = currentSelection()
  if (!info) {
    // A click on the chip collapses nothing (mousedown is prevented), so a missing
    // selection here really means the user moved on.
    if (!(state.shadow && state.shadow.activeElement && state.shadow.activeElement.classList.contains('chip'))) hideChip()
    return
  }
  state.pendingSel = info
  showChip(info)
}

function selectionSoon() {
  clearTimeout(state.timers.sel)
  state.timers.sel = setTimeout(onSelectionSettled, 160)
}

function setHoverBox(target) {
  const boxes = state.shadow && layer('boxes')
  if (!boxes) return
  let box = boxes.querySelector('.box.hover')
  if (!target) { if (box) box.remove(); return }
  if (!box) { box = el('div', { className: 'box hover' }); boxes.appendChild(box) }
  const r = target.getBoundingClientRect()
  Object.assign(box.style, { left: r.left + window.scrollX + 'px', top: r.top + window.scrollY + 'px', width: r.width + 'px', height: r.height + 'px' })
}

export function enterPickMode() {
  if (!isEnabled()) return
  ensureHost()
  closeCard({ restoreFocus: false })
  if (state.listOpen) { state.listOpen = false; renderList() }
  state.mode = 'pick'
  const bar = el('div', { className: 'chip modebar', role: 'status', 'data-modebar': '' })
  bar.appendChild(el('span', {}, 'Comment mode: click any item. Esc to stop.'))
  bar.appendChild(el('button', { type: 'button', className: 'btn', 'data-act': 'stop-pick' }, 'Stop'))
  layer('ui').appendChild(bar)
  announce('Comment mode. Click any item to comment on it. Press Escape to stop.')
  updateBubbleControls()
}

function exitPickMode() {
  if (state.mode !== 'pick') return
  state.mode = 'idle'
  setHoverBox(null)
  removeModebar()
  announce('Comment mode off.')
  updateBubbleControls()
}

function removeModebar() {
  const bar = state.shadow && state.shadow.querySelector('[data-modebar]')
  if (bar) bar.remove()
}

function onMouseOver(e) {
  if (state.mode !== 'pick') return
  const t = e.target
  if (!t || t.nodeType !== 1 || insideOurUi(t) || t === document.body || t === document.documentElement) { setHoverBox(null); return }
  setHoverBox(t)
}

function onClickCapture(e) {
  if (state.mode !== 'pick') return
  const t = e.target
  if (!t || t.nodeType !== 1 || insideOurUi(t)) return
  e.preventDefault()
  e.stopPropagation()
  const info = pickInfo(t)
  info.rect = (t.closest('canvas,svg,img,video,picture,iframe') || t).getBoundingClientRect()
  state.mode = 'idle'
  setHoverBox(null)
  removeModebar()
  updateBubbleControls()
  openCompose(info)
}

function onKeydown(e) {
  if (e.key !== 'Escape') return
  if (state.mode === 'pick') { exitPickMode(); return }
  if (state.mode === 'reattach') { state.mode = 'idle'; state.reattachId = null; hideChip(); announce('Re-attach cancelled.'); return }
  if (state.card) { closeCard(); return }
  if (state.listOpen) closeList()
}

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------

async function save(card) {
  const ta = card.querySelector('[data-compose]')
  const body = ta.value.trim()
  if (!body) { ta.focus(); return }
  const a = card._anchor
  const btn = card.querySelector('[data-act="save"]')
  btn.disabled = true
  try {
    const data = await api('POST', '', { page_comment: {
      body, page_path: normalizePath(window.location.pathname),
      anchor_quote: a.quote || '', anchor_prefix: a.prefix || '', anchor_suffix: a.suffix || '',
      anchor_selector: a.selector || '', anchor_label: a.label || ''
    } })
    state.comments.push(data.comment)
    try { window.getSelection().removeAllRanges() } catch (_) { /* fine */ }
    closeCard({ restoreFocus: true })
    if (!state.show) setShow(true)
    repaint()
    announce('Comment saved.')
  } catch (err) {
    btn.disabled = false
    announce(err.status === 401 || err.status === 422 ? 'Your session has expired. Sign in again; your comment is still in the box.' : `Comment not saved: ${err.message}`)
  }
}

function replaceComment(c) {
  const i = state.comments.findIndex((x) => String(x.id) === String(c.id))
  if (i >= 0) state.comments[i] = c
  else state.comments.push(c)
}

async function act(name, id, card) {
  const c = id != null ? byId(id) : null
  try {
    if (name === 'reply') {
      const ta = card.querySelector('[data-reply]')
      const body = ta.value.trim()
      if (!body) { ta.focus(); return }
      const data = await api('POST', `/${c.id}/reply`, { body })
      replaceComment(data.comment)
      openThread(c.id)
      announce('Reply saved.')
    } else if (name === 'resolve' || name === 'reopen') {
      const data = await api('PATCH', `/${c.id}`, { page_comment: { status: name === 'resolve' ? 'resolved' : 'open' } })
      replaceComment(data.comment)
      if (card) closeCard()
      repaint()
      announce(name === 'resolve' ? 'Comment resolved.' : 'Comment reopened.')
    } else if (name === 'delete') {
      if (!window.confirm('Delete this comment?')) return
      await api('DELETE', `/${c.id}`)
      state.comments = state.comments.filter((x) => String(x.id) !== String(c.id))
      closeCard()
      repaint()
      announce('Comment deleted.')
    } else if (name === 'reattach') {
      closeCard({ restoreFocus: false })
      if (state.listOpen) { state.listOpen = false; renderList() }
      state.mode = 'reattach'
      state.reattachId = c.id
      announce('Select the new text for this comment, then press Re-attach here.')
    }
  } catch (err) {
    announce(`That did not work: ${err.message}`)
  }
}

async function reattachTo(info) {
  const id = state.reattachId
  state.mode = 'idle'
  state.reattachId = null
  hideChip()
  try {
    const data = await api('PATCH', `/${id}`, { page_comment: {
      anchor_state: 'attached', anchor_quote: info.quote, anchor_prefix: info.prefix,
      anchor_suffix: info.suffix, anchor_selector: info.selector, anchor_label: info.label
    } })
    replaceComment(data.comment)
    state.reported.delete(String(id))
    try { window.getSelection().removeAllRanges() } catch (_) { /* fine */ }
    if (!state.show) setShow(true)
    repaint()
    announce('Comment re-attached.')
  } catch (err) {
    announce(`Not re-attached: ${err.message}`)
  }
}

function onShadowClick(e) {
  const t = e.target.closest && e.target.closest('[data-pin], [data-act]')
  if (!t) return
  e.stopPropagation()
  if (t.hasAttribute('data-pin')) {
    state.lastFocus = t
    if (String(state.activeId) === t.getAttribute('data-pin')) closeCard()
    else openThread(t.getAttribute('data-pin'))
    return
  }
  const name = t.getAttribute('data-act')
  const card = t.closest('.card')
  const id = t.getAttribute('data-id') || (card && card.getAttribute('data-id'))
  switch (name) {
    case 'chip': {
      const info = state.pendingSel || currentSelection()
      if (!info) return
      if (state.mode === 'reattach') reattachTo(info)
      else openCompose(info)
      break
    }
    case 'save': save(card); break
    case 'cancel': case 'close': closeCard(); break
    case 'open': state.listOpen = false; renderList(); openThread(id); break
    case 'close-list': closeList(); break
    case 'pick': enterPickMode(); break
    case 'stop-pick': exitPickMode(); break
    case 'add-selected': {
      const info = state.pendingSel || currentSelection()
      if (!info) { announce('Select some text on the page first.'); return }
      state.listOpen = false
      renderList()
      openCompose(info)
      break
    }
    case 'toggle-resolved':
      state.includeResolved = t.checked
      refresh().then(renderList)
      break
    default: act(name, id, card)
  }
}

// Enter sends, Shift+Enter is a newline; Tab stays inside an open card or list.
function onShadowKeydown(e) {
  const ta = e.target
  if (e.key === 'Enter' && !e.shiftKey && ta.tagName === 'TEXTAREA') {
    e.preventDefault()
    const card = ta.closest('.card')
    if (ta.hasAttribute('data-compose')) save(card)
    else act('reply', card.getAttribute('data-id'), card)
    return
  }
  if (e.key === 'Escape') { e.stopPropagation(); onKeydown(e); return }
  if (e.key === 'Tab') {
    const box = ta.closest && ta.closest('.card, .list')
    if (!box) return
    const f = Array.from(box.querySelectorAll('button, textarea, input')).filter((n) => !n.disabled)
    if (!f.length) return
    const i = f.indexOf(state.shadow.activeElement)
    if (e.shiftKey && i <= 0) { e.preventDefault(); f[f.length - 1].focus() } else if (!e.shiftKey && i === f.length - 1) { e.preventDefault(); f[0].focus() }
  }
}

// ---------------------------------------------------------------------------
// Feedback bubble controls (mounted into the bubble, wired by delegation so a
// Turbo-cached clone of the bubble still works)
// ---------------------------------------------------------------------------

export function setShow(on) {
  state.show = Boolean(on)
  saveShow(state.show)
  if (!state.show) {
    closeCard({ restoreFocus: false })
    if (state.listOpen) { state.listOpen = false; renderList() }
    clearHighlight()
    setHoverBox(null)
    if (state.mode === 'pick') { state.mode = 'idle'; removeModebar() }
  }
  paintPins()
  updateBubbleControls()
}

function updateBubbleControls() {
  const bubble = document.getElementById('llamapress-feedback-bubble')
  if (!bubble || !isEnabled()) return
  const count = openComments().length

  let badge = bubble.querySelector('[data-llama-pc="badge"]')
  if (!badge) {
    badge = el('button', {
      type: 'button', 'data-llama-pc': 'badge',
      style: 'position:absolute;top:-6px;left:-6px;min-width:22px;height:22px;padding:0 6px;border-radius:999px;border:2px solid #fff;background:#6d28d9;color:#fff;font:700 11px/18px system-ui,sans-serif;cursor:pointer;'
    })
    bubble.appendChild(badge)
  }
  badge.textContent = count > 99 ? '99+' : String(count)
  badge.setAttribute('aria-label', `${count} open comment${count === 1 ? '' : 's'} on this page. Show comments`)
  badge.hidden = state.show || count === 0

  const home = bubble.querySelector('#content-feedback')
  if (!home) return
  let box = home.querySelector('[data-llama-pc="controls"]')
  if (!box) {
    box = el('div', { 'data-llama-pc': 'controls', style: 'display:flex;flex-wrap:wrap;gap:8px;align-items:center;padding:8px 12px 0;font:13px system-ui,sans-serif;color:#111827;' })
    const sw = el('button', { type: 'button', role: 'switch', 'data-llama-pc': 'switch', style: 'display:inline-flex;align-items:center;gap:6px;border:0;background:none;padding:4px 0;cursor:pointer;font:inherit;color:inherit;' })
    const track = el('span', { 'data-llama-pc': 'track', 'aria-hidden': 'true', style: 'display:inline-flex;align-items:center;width:32px;height:18px;padding:2px;border-radius:999px;' })
    track.appendChild(el('span', { 'data-llama-pc': 'knob', style: 'display:block;width:14px;height:14px;border-radius:50%;background:#fff;' }))
    sw.appendChild(track)
    sw.appendChild(el('span', { 'data-llama-pc': 'switch-label' }, 'Show comments'))
    box.appendChild(sw)
    box.appendChild(el('button', { type: 'button', 'data-llama-pc': 'pick', style: 'border:0;background:none;padding:4px 0;color:#5b21b6;text-decoration:underline;cursor:pointer;font:inherit;' }, 'Comment on this page'))
    box.appendChild(el('button', { type: 'button', 'data-llama-pc': 'list', style: 'border:0;background:none;padding:4px 0;color:#5b21b6;text-decoration:underline;cursor:pointer;font:inherit;' }, 'All comments'))
    home.insertBefore(box, home.firstChild)
  }
  const sw = box.querySelector('[data-llama-pc="switch"]')
  sw.setAttribute('aria-checked', String(state.show))
  box.querySelector('[data-llama-pc="switch-label"]').textContent = `Show comments${count ? ` (${count})` : ''}`
  const track = box.querySelector('[data-llama-pc="track"]')
  track.style.background = state.show ? '#6d28d9' : '#6b7280'
  box.querySelector('[data-llama-pc="knob"]').style.marginLeft = state.show ? '14px' : '0'
}

function onDocumentClick(e) {
  const t = e.target && e.target.closest && e.target.closest('[data-llama-pc]')
  if (!t || !isEnabled()) return
  const what = t.getAttribute('data-llama-pc')
  if (what === 'switch' || what === 'switch-label' || what === 'track' || what === 'knob') { setShow(!state.show); announce(state.show ? 'Comments shown.' : 'Comments hidden.') }
  else if (what === 'badge') { e.preventDefault(); e.stopPropagation(); setShow(true); openList() }
  else if (what === 'pick') { if (!state.show) setShow(true); closeBubblePanel(); enterPickMode() }
  else if (what === 'list') { if (!state.show) setShow(true); closeBubblePanel(); openList() }
}

function closeBubblePanel() {
  const panel = document.getElementById('feedback-panel')
  const trigger = document.getElementById('feedback-trigger')
  if (panel && !panel.classList.contains('hidden') && trigger) trigger.click()
}

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

async function refresh() {
  const path = normalizePath(window.location.pathname)
  const q = `?path=${encodeURIComponent(path)}${state.includeResolved ? '&include_resolved=1' : ''}`
  const data = await api('GET', q)
  if (normalizePath(window.location.pathname) !== path) return
  state.me = data.me
  state.comments = data.comments || []
  repaint()
}

function openFromHash() {
  const m = /^#llama-comment-(\d+)$/.exec(window.location.hash || '')
  if (!m) return
  if (!state.show) setShow(true)
  if (byId(m[1])) openThread(m[1])
  else if (!state.includeResolved) { state.includeResolved = true; refresh().then(() => byId(m[1]) && openThread(m[1])) }
}

function onMutations(records) {
  for (const r of records) {
    const t = r.target
    if (t === state.host || (state.host && state.host.contains(t))) continue
    if (t.nodeType === 1 && t.closest && t.closest(SKIP_SELECTOR)) continue
    if (t.parentElement && t.parentElement.closest(SKIP_SELECTOR)) continue
    repaintSoon()
    return
  }
}

function bindDocumentListeners() {
  if (state.listenersBound) return
  state.listenersBound = true
  document.addEventListener('mouseup', selectionSoon)
  document.addEventListener('keyup', (e) => { if (e.key !== 'Escape') selectionSoon() })
  document.addEventListener('touchend', selectionSoon)
  document.addEventListener('selectionchange', selectionSoon)
  document.addEventListener('mouseover', onMouseOver, true)
  document.addEventListener('click', onClickCapture, true)
  document.addEventListener('click', onDocumentClick)
  document.addEventListener('keydown', onKeydown)
  window.addEventListener('resize', repaintSoon)
  window.addEventListener('hashchange', openFromHash)
}

export async function init() {
  teardown()
  if (!isEnabled() || !document.body) return
  bindDocumentListeners()
  state.page = normalizePath(window.location.pathname)
  state.loadedAt = Date.now()
  state.timers.grace = setTimeout(repaintSoon, DETACH_GRACE_MS + 50)
  state.show = loadShow()
  ensureHost()
  updateBubbleControls()
  if (window.ResizeObserver) {
    const ro = new ResizeObserver(repaintSoon)
    ro.observe(document.documentElement)
    state.observers.push(ro)
  }
  if (window.MutationObserver) {
    const mo = new MutationObserver(onMutations)
    mo.observe(document.body, { childList: true, subtree: true, characterData: true })
    state.observers.push(mo)
  }
  try {
    await refresh()
    openFromHash()
  } catch (err) {
    if (err.status !== 401 && err.status !== 404) console.warn('[PageComments] could not load comments:', err.message)
  }
}

// Everything injected comes out before Turbo snapshots the page, so a Back/Forward
// clone never carries a dead host, and Leo never sees one.
export function teardown() {
  state.observers.forEach((o) => o.disconnect())
  state.observers = []
  Object.values(state.timers).forEach((t) => clearTimeout(t))
  state.timers = {}
  clearHighlight()
  if (state.host) state.host.remove()
  document.querySelectorAll(HOST_TAG).forEach((n) => n.remove())
  if (state.styleTag) state.styleTag.remove()
  document.querySelectorAll('[data-llama-pc="controls"], [data-llama-pc="badge"]').forEach((n) => n.remove())
  Object.assign(state, {
    host: null, shadow: null, styleTag: null, card: null, activeId: null, listOpen: false,
    mode: 'idle', reattachId: null, pendingSel: null, lastFocus: null, comments: [], me: null
  })
  state.anchors.clear()
  state.reported.clear()
}

// Part C: the open comments on this page, for the page context sent to Leo.
export function forLeo() {
  return openComments().slice(0, LEO_MAX).map((c) => ({
    id: c.id,
    quote: c.quote ? short(c.quote, 200) : null,
    label: c.label || null,
    body: String(c.body || '').slice(0, LEO_BODY_MAX),
    author: c.author ? c.author.name : null,
    state: state.anchors.has(String(c.id)) ? 'attached' : 'detached'
  }))
}

// Removes our injected host and style from serialized page HTML (the page context
// sent to Leo). The shadow content never serializes; the host tag would.
export function stripInjectedMarkup(html) {
  return String(html || '')
    .replace(/<llama-comments\b[^>]*>[\s\S]*?<\/llama-comments>/gi, '')
    .replace(/<style\b[^>]*data-lp-injected[^>]*>[\s\S]*?<\/style>/gi, '')
}

// Test hook.
export function _state() { return state }

window.llamaPageComments = { forLeo, init, teardown, setShow, enterPickMode }

document.addEventListener('turbo:load', init)
document.addEventListener('turbo:before-cache', teardown)
if (document.readyState !== 'loading') {
  // Loaded after the first turbo:load (or without Turbo): start now.
  if (!window.Turbo) init()
} else {
  document.addEventListener('DOMContentLoaded', () => { if (!window.Turbo) init() })
}
