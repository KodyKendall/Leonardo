---
title: Generate PDFs (headless Chrome) without wedging your app
slug: pdf-generation
category: Files
summary: A naive `grover.to_pdf` in a controller can freeze your entire app (blank screen / infinite spinner). Funnel every PDF render through one safe helper — single-flight, hard timeout, self-contained HTML — so a slow or hung render can never take the app down.
tags: [pdf, grover, headless-chrome, performance, puma, files]
status: stable
visibility: public
source_project: leo-note.leo.llamapress.ai
layers: [controller, view, stimulus_js]
---

# Generate PDFs (headless Chrome) without wedging your app

> ⚠️ **Cookbook example — not live code.** (KEEP THIS CALLOUT.) Every code block below
> is an **example snippet**, **not part of the llamapress.ai codebase**, and **not
> running on this server**. This is a reference recipe for a **Leo instance (an AI coding
> agent) to implement in its own app** — read it to understand the pattern, then recreate
> it there.

Generating a PDF from HTML with [Grover](https://github.com/Studiosity/grover) (which
drives a headless Chromium under the hood) is easy to ship — and easy to take your whole
app down with. A plain `grover.to_pdf` inside a controller action is **synchronous, slow
(seconds), and memory-heavy**, and on a small server it can freeze *every* page for *every*
user: blank screen, infinite loading spinner, no error. This guide is the safe pattern —
the same shape works for `wkhtmltopdf`, `weasyprint`, or any headless-browser render.

> **When to use:** any "Export / Download / Print PDF" button backed by HTML → PDF.
> **When not to:** if a library can build the PDF in-process without a browser (e.g.
> Prawn for simple tabular docs), prefer that — it has none of these failure modes.

---

## Why the naive version takes your whole app down

Your web server (Puma) runs a **small, fixed pool of threads** — often just 3. Each thread
serves one request at a time. A headless-Chrome PDF render is uniquely hostile to that pool:

1. **No timeout by default.** `grover.to_pdf` will wait *forever* if Chrome hangs. That
   thread is now gone — permanently.
2. **It's heavy.** Each render launches a Chromium worth a few hundred MB. Two or three at
   once can exhaust RAM and get OOM-killed.
3. **It calls back into your own server.** With `display_url` set, Chrome fetches the
   page's CSS/JS/images *over HTTP from your app* — consuming *more* of the same tiny
   thread pool. If the pool is busy, Chrome's asset requests can't be served, the render
   stalls, and you deadlock.

So a user clicks "Export PDF" a few times (because it feels stuck), the slow/hung renders
eat all 3 threads, and **the entire app wedges** until someone restarts it.

> **Diagnosing a wedge (so you recognize it):** every page hangs with no error; the Rails
> log *stops* — no new `Started GET` lines even though requests are arriving; `curl
> localhost:3000/` from inside the container hangs (times out) instead of refusing;
> `Started` log lines far outnumber `Completed`. Immediate unstick: restart the web
> process. Durable fix: this guide.

---

## The 80/20 in one breath

1. Render your HTML to a string as usual.
2. Funnel **every** PDF render through one helper, `safe_pdf` / `pdf_with_lock`, that:
   (a) lets only **one** render run at a time (reject extras — don't queue them),
   (b) hard-caps total time, (c) gives Chrome its own timeouts, (d) turns any failure into
   a friendly redirect instead of a 500 or a frozen thread.
3. Make the print HTML **self-contained** (inline CSS, inline/`data:` images) so Chrome
   needs **zero** subrequests back to your server.
4. Put a **loading state** on the export button so one click can't become five.
5. Only if you truly need concurrent PDFs: move generation to a **background job** (needs
   a real queue). Most apps never need this.

---

## Layer 1 — The controller helper (this is the whole fix)

Add one private helper and route every PDF action through it. This is plain app code — no
gems to add, no server config to change.

```ruby
# app/controllers/<your>_controller.rb  (or a concern included by ApplicationController)

# How long a single render may take before we give up (seconds).
PDF_RENDER_TIMEOUT = (ENV["PDF_RENDER_TIMEOUT_S"] || 25).to_i
# Process-wide guard: only ONE headless Chrome runs at a time.
PDF_RENDER_LOCK = Mutex.new

# Render a Grover PDF safely. Returns the PDF bytes, or raises Timeout::Error
# (which the caller rescues into a friendly redirect). Two failure modes are
# deadly on a small Puma pool, and this closes both:
#   * a slow/hung render holding a web thread forever -> hard time cap.
#   * several concurrent renders each launching their own Chrome (RAM blow-up)
#     AND starving each other's asset fetches -> single-flight (one at a time).
# We REJECT extra renders rather than queue them: queueing would hold the other
# Puma threads while waiting and, because Chrome fetches assets back from this
# same server, starve those fetches and deadlock the pool anyway.
def pdf_with_lock(grover)
  unless PDF_RENDER_LOCK.try_lock
    raise Timeout::Error, "another PDF is already rendering"
  end
  begin
    Timeout.timeout(PDF_RENDER_TIMEOUT) { grover.to_pdf }
  rescue Timeout::Error
    raise
  rescue => e
    Rails.logger.error("[PDF] render failed (action=#{action_name}): #{e.class}: #{e.message}")
    raise Timeout::Error, "pdf render failed (#{e.class})"  # normalize -> one rescue path
  ensure
    PDF_RENDER_LOCK.unlock if PDF_RENDER_LOCK.owned?
  end
end
private :pdf_with_lock
```

Every PDF action then looks like this — note Grover's **own** timeout options, which make
Chrome abort cleanly (no orphaned browser process) before the Ruby backstop fires:

```ruby
# app/controllers/<your>_controller.rb
def export_report_pdf
  @report = current_user.reports.find(params[:id])
  html = render_to_string(layout: false, template: "reports/pdf", formats: [:html])

  grover = Grover.new(
    html,
    format: "A4",
    margin: { top: "10mm", bottom: "10mm", left: "12mm", right: "12mm" },
    print_background: true,
    prefer_css_page_size: true,
    # Chrome-level timeouts (ms) -> a stuck render tears Chrome down cleanly.
    # Keep them a few seconds UNDER PDF_RENDER_TIMEOUT so Chrome aborts first.
    launch_timeout:  (PDF_RENDER_TIMEOUT - 5) * 1000,
    convert_timeout: (PDF_RENDER_TIMEOUT - 5) * 1000,
    timeout:         (PDF_RENDER_TIMEOUT - 5) * 1000
  )

  begin
    pdf_data = pdf_with_lock(grover)
  rescue Timeout::Error
    redirect_back(fallback_location: root_path,
                  alert: "PDF generation is busy or timed out — please try again.")
    return
  end

  send_data pdf_data, filename: "report-#{Date.today}.pdf",
                      type: "application/pdf", disposition: "inline"
end
```

That's it. Every render is now bounded in time, never runs concurrently, and fails as a
redirect instead of a frozen page.

## Layer 2 — Make the print HTML self-contained (kills the deadlock)

The sneakiest failure is Chrome fetching your assets back over HTTP. Avoid it: the PDF
template should not depend on your server serving anything.

```erb
<%# app/views/reports/pdf.html.erb %>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <style>
      /* Inline ALL styling here. Do NOT <%%= stylesheet_link_tag %> a same-origin
         asset — that makes Chrome call back into your app to fetch it. */
      body { font-family: Arial, sans-serif; color: #111; }
      .title { font-size: 20px; font-weight: 700; }
      table { width: 100%; border-collapse: collapse; }
      td, th { border: 1px solid #ddd; padding: 6px; }
    </style>
  </head>
  <body>
    <div class="title"><%= @report.name %></div>
    <%# Images: prefer a data: URI or an absolute CDN URL, not a relative /assets path. %>
    <!-- ... -->
  </body>
</html>
```

If you genuinely must load a same-origin asset, you can, but only because the single-flight
guard leaves the other threads free to serve Chrome's fetches — keep the asset count tiny.

## Layer 3 — A loading state on the button (so one click ≠ five)

A slow export with no feedback gets spam-clicked. Disable the trigger and show a spinner
the moment it's clicked. (See the companion guide **async-action-feedback** for the full
pattern.)

```erb
<%# app/views/reports/show.html.erb %>
<a href="<%= export_report_pdf_path(@report) %>"
   data-controller="busy" data-action="busy#go"
   class="btn">
  <span data-busy-target="idle">⬇️ Export PDF</span>
  <span data-busy-target="working" class="hidden">Generating…</span>
</a>
```

```javascript
// app/javascript/controllers/busy_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["idle", "working"]
  go() {
    this.idleTarget.classList.add("hidden")
    this.workingTarget.classList.remove("hidden")
    this.element.classList.add("pointer-events-none", "opacity-60")
    // The browser navigates to the PDF; reset shortly after in case it streams inline.
    setTimeout(() => {
      this.idleTarget.classList.remove("hidden")
      this.workingTarget.classList.add("hidden")
      this.element.classList.remove("pointer-events-none", "opacity-60")
    }, 8000)
  }
}
```

---

## Advanced — move it to a background job (only if you need concurrency)

The synchronous helper above is enough for the vast majority of apps (a handful of PDF
exports a day). If you need *many concurrent* exports, generate in a background job so web
threads are never spent on rendering at all:

1. Controller enqueues `GeneratePdfJob.perform_later(record.id)` and renders a "preparing
   your PDF…" page.
2. The job renders with Grover and attaches the result via **Active Storage**
   (`record.pdf.attach(io: StringIO.new(bytes), filename: ...)`).
3. The page polls a small status endpoint (or uses Turbo Streams) and, when ready, shows
   a download link to the Active Storage blob.

> **Caveat — this needs a real out-of-process queue.** With the default in-process job
> adapter (`:async`), jobs run in the *same* process and still compete for memory/CPU, so
> you gain little. Only adopt the job pattern if your app has a proper worker (e.g.
> Sidekiq) running. If it doesn't, stick with the synchronous safe helper above — it's
> fully sufficient and needs zero infrastructure.

---

## Gotchas (the hard-won stuff)

- **`grover.to_pdf` has no timeout by default.** A hung Chrome holds a web thread *forever*
  and, on a small thread pool, a few of those freeze the entire app. Always wrap it.
- **Your thread pool is tiny.** Puma defaults to ~3 threads in development. Three stuck
  renders = a dead app. **Don't "fix" this by cranking `RAILS_MAX_THREADS`** — on a small
  box more threads just means more concurrent Chrome and an OOM kill. Bound the work, don't
  widen the door.
- **Reject, don't queue.** Use `Mutex#try_lock` (reject the extra render) — **not**
  `Mutex#synchronize` (queue it). Queued requests sit holding their own threads while they
  wait, and because Chrome fetches assets back from the same server, that re-creates the
  deadlock. Rejecting frees the thread instantly.
- **`display_url` makes Chrome call back into your app.** It fetches the page's assets over
  HTTP using your Puma threads. Inline your CSS/images so it needs none.
- **Give Chrome its own timeouts** (`launch_timeout` / `convert_timeout` / `timeout`) a few
  seconds *below* your Ruby timeout, so Chrome aborts and cleans itself up first — otherwise
  a Ruby-level timeout can leave an orphaned Chrome process eating RAM.
- **Avoid `wait_until: "networkidle0"` for print HTML.** A page with a persistent
  connection (ActionCable, long-poll, analytics beacons) never goes "network idle", so the
  render waits until it times out. Render static, self-contained HTML.
- **Normalize errors to one path.** Convert any Grover/Chrome exception into the same
  timeout/redirect branch, so a render failure is a friendly "try again" — never a 500 or a
  spinner that never resolves.

---

## Files this pattern touches

```
app/controllers/<your>_controller.rb     # PDF_RENDER_TIMEOUT + PDF_RENDER_LOCK + pdf_with_lock; each action calls it
app/views/<resource>/pdf.html.erb         # self-contained print HTML (inline CSS/images)
app/views/<resource>/show.html.erb        # export button with a loading state
app/javascript/controllers/busy_controller.js  # (optional) Stimulus loading state
```

## How to adapt to your app

1. Drop `PDF_RENDER_TIMEOUT`, `PDF_RENDER_LOCK`, and `pdf_with_lock` into the controller
   that has your PDF actions (or a concern mixed into `ApplicationController` if several
   controllers render PDFs — one lock for the whole app is correct).
2. In **each** PDF action, add the three Grover timeout options and replace
   `pdf_data = grover.to_pdf` with `pdf_data = pdf_with_lock(grover)` wrapped in the
   `rescue Timeout::Error -> redirect_back` shown above.
3. Make each print template self-contained (inline styles, no same-origin asset links).
4. Add the button loading state.
5. Leave `PDF_RENDER_TIMEOUT` at 25s unless your documents are unusually large; raise it a
   little if legitimate renders approach the cap, but keep the Chrome timeouts a few seconds
   under it.
