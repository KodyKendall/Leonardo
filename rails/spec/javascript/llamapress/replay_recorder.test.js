import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

// Feedback Replay, MVP. A feedback note arrived as a sentence, a URL and one selector,
// so every note had to be reconstructed by asking the client what they had been doing.
// The browser now keeps the last ~5 minutes of the page in memory (rrweb) and sends it
// with the note as ONE attachment. Nothing leaves the browser unless a note is sent,
// and nothing is recorded at all unless the app turned the feature on.
//
// rrweb takes a fresh full snapshot every minute ("checkout"). Each minute is kept as
// its own segment starting at that snapshot, so dropping the oldest segment always
// leaves a recording that still plays from its first event.

const MODULE = '../../../app/javascript/llamapress/replay_recorder.js'

let mod

beforeEach(async () => {
  vi.resetModules()
  delete window.llamaFeedbackReplay
  delete window.rrwebRecord
  window.llamapressConfig = {}
  mod = await import(MODULE)
})

afterEach(() => {
  vi.restoreAllMocks()
  delete window.llamaFeedbackReplay
  delete window.rrwebRecord
  delete window.llamapressConfig
})

const ev = (type, n = 0) => ({ type, timestamp: 1_000 + n, data: {} })

describe('the rolling buffer', () => {
  it('keeps only the newest five one-minute segments', () => {
    const buf = new mod.ReplayBuffer()
    for (let minute = 0; minute < 8; minute++) {
      buf.push(ev(2, minute), minute > 0)      // a checkout starts each new minute
      buf.push(ev(3, minute))
    }
    const events = buf.events()
    expect(buf.segments.length).toBe(mod.KEEP_SEGMENTS)
    expect(events[0].timestamp).toBe(1_000 + 3) // minutes 3..7 survive
    expect(events).toHaveLength(10)
  })

  it('drops the oldest minute when too many events pile up, never the current one', () => {
    const buf = new mod.ReplayBuffer({ maxEvents: 6 })
    buf.push(ev(2, 0))
    for (let i = 0; i < 4; i++) buf.push(ev(3, i))
    buf.push(ev(2, 10), true)
    for (let i = 0; i < 4; i++) buf.push(ev(3, 10 + i))
    expect(buf.segments.length).toBe(1)
    expect(buf.events()[0].timestamp).toBe(1_000 + 10)
  })
})

describe('the file sent with a note', () => {
  it('is one gzip file named replay-<time>.json.gz holding the events', async () => {
    const buf = new mod.ReplayBuffer()
    buf.push(ev(4)); buf.push(ev(2, 1)); buf.push(ev(3, 2))

    const file = await mod.replayFile(buf)

    expect(file.name).toMatch(/^replay-[\w.:-]+\.json\.gz$/)
    expect(file.type).toBe('application/gzip')
    const text = await new Response(file.stream().pipeThrough(new DecompressionStream('gzip'))).text()
    const payload = JSON.parse(text)
    expect(payload.events).toHaveLength(3)
    expect(payload.url).toBe(window.location.href)
  })

  it('is nothing at all when there is nothing to play', async () => {
    expect(await mod.replayFile(new mod.ReplayBuffer())).toBeNull()
  })

  it('sheds the oldest minutes to fit the server cap instead of failing', async () => {
    const buf = new mod.ReplayBuffer()
    for (let minute = 0; minute < 3; minute++) {
      // A real minute opens with a meta event then a full snapshot.
      buf.push({ type: 4, timestamp: minute, data: {} }, minute > 0)
      buf.push({ type: 2, timestamp: minute, data: { junk: crypto.randomUUID().repeat(2000) } })
    }
    const whole = await mod.replayFile(buf)
    const file = await mod.replayFile(buf, { maxBytes: Math.ceil(whole.size / 2) })
    expect(file.size).toBeLessThanOrEqual(Math.ceil(whole.size / 2))
    const text = await new Response(file.stream().pipeThrough(new DecompressionStream('gzip'))).text()
    expect(JSON.parse(text).events.at(-1).timestamp).toBe(2) // the newest minute is kept
  })
})

describe('starting the recorder', () => {
  it('records nothing when the app has not turned Feedback Replay on', async () => {
    const load = vi.fn()
    await mod.startReplay({ loadScript: load })
    expect(load).not.toHaveBeenCalled()
    expect(window.llamaFeedbackReplay).toBeUndefined()
  })

  it('masks every input and honours data-llama-no-replay', async () => {
    window.llamapressConfig = { feedbackReplayEnabled: true }
    const record = vi.fn(() => () => {})
    window.rrwebRecord = { record }

    await mod.startReplay({ loadScript: async () => {} })

    const opts = record.mock.calls[0][0]
    expect(opts.maskAllInputs).toBe(true)
    expect(opts.blockSelector).toContain('[data-llama-no-replay]')
    expect(opts.checkoutEveryNms).toBe(60_000)
    expect(typeof window.llamaFeedbackReplay.snapshotFile).toBe('function')
  })

  it('a recorder that fails to load leaves feedback working, just without a replay', async () => {
    window.llamapressConfig = { feedbackReplayEnabled: true }
    vi.spyOn(console, 'warn').mockImplementation(() => {})
    await mod.startReplay({ loadScript: async () => { throw new Error('blocked') } })
    expect(window.llamaFeedbackReplay).toBeUndefined()
  })
})
