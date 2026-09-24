// Feedback Replay: keep the last few minutes of this page in memory, and hand them to
// the feedback bubble as one file when a note is sent.
//
// A note used to arrive as a sentence, a URL and one selector, so every note had to be
// reconstructed by asking the client what they had been doing. rrweb records the page
// as DOM snapshots + changes (not video), and the gem's replay page plays it back.
//
// - Off unless the app turned it on (window.llamapressConfig.feedbackReplayEnabled).
// - Nothing leaves the browser unless a note is sent.
// - Every input is masked; anything under [data-llama-no-replay] is not recorded.
// - A full page load starts a new recording (Turbo visits keep the same one).

export const RRWEB_RECORD_SRC = 'https://cdn.jsdelivr.net/npm/@rrweb/record@2.1.6/umd/record.min.js'

// rrweb takes a fresh full snapshot every minute; each minute is kept as its own
// segment starting at that snapshot, so the recording always plays from its first
// event after older minutes are dropped.
export const CHECKOUT_MS = 60_000
export const KEEP_SEGMENTS = 5
// A heavy page (a big table re-rendering) can pile up events fast. Past this, the
// oldest minute goes early, so memory stays bounded.
export const MAX_EVENTS = 50_000
// The server refuses anything larger (UserFeedbacksController::REPLAY_MAX_BYTES).
export const MAX_UPLOAD_BYTES = 5 * 1024 * 1024

export class ReplayBuffer {
  constructor({ keepSegments = KEEP_SEGMENTS, maxEvents = MAX_EVENTS } = {}) {
    this.keepSegments = keepSegments
    this.maxEvents = maxEvents
    this.segments = [[]]
    this.count = 0
  }

  push(event, isCheckout = false) {
    if (isCheckout) {
      this.segments.push([])
      while (this.segments.length > this.keepSegments) this.dropOldest()
    }
    this.segments[this.segments.length - 1].push(event)
    this.count += 1
    while (this.count > this.maxEvents && this.segments.length > 1) this.dropOldest()
  }

  dropOldest() {
    this.count -= this.segments.shift().length
  }

  events(fromSegment = 0) {
    return this.segments.slice(fromSegment).flat()
  }
}

async function gzip(text) {
  const stream = new Blob([text]).stream().pipeThrough(new CompressionStream('gzip'))
  return await new Response(stream).blob()
}

// The file sent with a note, or null when there is nothing worth playing. Drops the
// oldest minutes until it fits under the server's cap.
export async function replayFile(buffer, { maxBytes = MAX_UPLOAD_BYTES } = {}) {
  for (let from = 0; from < buffer.segments.length; from++) {
    const events = buffer.events(from)
    if (events.length < 2) return null
    const payload = JSON.stringify({
      version: 1,
      url: window.location.href,
      recordedUntil: new Date().toISOString(),
      events
    })
    const blob = await gzip(payload)
    if (blob.size <= maxBytes) {
      const stamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
      return new File([blob], `replay-${stamp}.json.gz`, { type: 'application/gzip' })
    }
  }
  return null
}

function loadScriptOnce(src) {
  return new Promise((resolve, reject) => {
    const script = document.createElement('script')
    script.src = src
    script.async = true
    script.onload = resolve
    script.onerror = () => reject(new Error(`Failed to load ${src}`))
    document.head.appendChild(script)
  })
}

export async function startReplay({ loadScript = loadScriptOnce } = {}) {
  if (!(window.llamapressConfig || {}).feedbackReplayEnabled) return
  if (window.llamaFeedbackReplay) return

  try {
    if (!window.rrwebRecord) await loadScript(RRWEB_RECORD_SRC)
    const record = window.rrwebRecord?.record || window.rrwebRecord
    const buffer = new ReplayBuffer()
    record({
      emit: (event, isCheckout) => buffer.push(event, isCheckout),
      checkoutEveryNms: CHECKOUT_MS,
      maskAllInputs: true,
      blockSelector: '[data-llama-no-replay]'
    })
    window.llamaFeedbackReplay = { snapshotFile: () => replayFile(buffer) }
  } catch (err) {
    // Feedback still works; it just arrives without a replay.
    console.warn('Feedback Replay unavailable:', err?.message)
  }
}

// After the page settles, so recording never competes with the page's own first paint.
function whenIdle(fn) {
  if ('requestIdleCallback' in window) window.requestIdleCallback(fn, { timeout: 5000 })
  else setTimeout(fn, 2000)
}

// import.meta.env only exists under the test runner, which drives startReplay itself.
if (typeof window !== 'undefined' && import.meta.env?.MODE !== 'test') {
  whenIdle(() => startReplay())
}
