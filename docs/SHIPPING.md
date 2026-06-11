# Shipping Without Heroics

How code gets from a laptop to production with automated confidence at every
step. The goal: **you never have to manually test the stack before deploying.**
If the pipeline is green, ship it.

## The system at a glance

```
LlamaBot repo (agents, chat UI, FastAPI)
  push to *-alpha / PR to main
    → CI: pytest  +  E2E vs Leonardo stack (browser + mock LLM)   [free, ~10 min]
  git tag vX.Y.Z
    → Release: build → boot smoke → push kody06/llamabot:X.Y.Z    [gated publish]

LlamaPress-Simple repo (Rails skeleton image)
  PR / push to main
    → CI: brakeman, importmap audit, rspec
  git tag vX.Y.Z
    → Release: build → boot smoke → push kody06/llamapress-simple:X.Y.Z

Leonardo repo (the composition: pinned images + overlay code + e2e suite)
  PR / push to main
    → CI: ERB lint  +  RSpec  +  E2E smoke (real browser vs pinned stack)
  every night at 12:00 UTC
    → E2E Nightly: REAL LLM ticket-mode run; opens a GitHub issue on failure
```

Three layers of protection, by cost:

| Tier | When | LLM | What it catches |
|------|------|-----|-----------------|
| Unit/spec (pytest, rspec) | every PR | none | logic regressions inside one repo |
| E2E smoke + mock (Playwright) | every PR | none / fake | login, WebSocket, agent routing, UI rendering, stack boot |
| E2E nightly (Playwright) | daily + on demand | **real DeepSeek** | prompt drift, model/API changes, the actual product flow (ticket mode → row in Postgres) |

## Day-to-day workflows

### Changing LlamaBot (agents, prompts, chat UI)

1. Work on the `*-alpha` branch as usual. Every push runs pytest **and** the
   full-stack e2e job (your commit's image inside the real Leonardo compose).
2. Green? Keep going. Red? The Playwright report artifact on the run page has
   a video + trace of exactly what the browser saw.
3. Ready to release: `git tag v0.5.1 && git push origin v0.5.1`.
   The Release workflow builds, boot-tests, and publishes
   `kody06/llamabot:0.5.1`. **No more `docker buildx --push` from a laptop.**
4. Bump the tag in Leonardo's `docker-compose.yml`, open a PR. Leonardo's
   e2e-smoke job validates the new composition in a real browser before merge.

### Changing the Rails skeleton (LlamaPress-Simple)

Same shape: PR → CI; `git tag vX.Y.Z` → gated publish of
`kody06/llamapress-simple:X.Y.Z`; bump the tag in Leonardo and let its CI
validate the composition.

### Changing Leonardo (overlay code, compose, agents config)

Open a PR. ERB lint + RSpec + e2e smoke all run against the pinned images.
Merge when green.

### Before a risky deploy (optional, ~10 min)

Actions tab → **E2E Nightly (real LLM)** → "Run workflow". Same canary the
cron runs every night, on demand. This is the button that replaces "Kody
manually clicks through ticket mode."

## When the nightly fails

A GitHub issue is opened automatically (title: "Nightly e2e (real LLM)
failed — <date>"). On the run page:

1. **Playwright report artifact** — video + trace of the browser session.
2. **Container logs** — llamabot + llamapress tails are printed in the run.

Common causes, in order of likelihood: an agent/prompt regression in the
pinned llamabot image, a DeepSeek API change/outage, stack boot failure
(check the "Wait for chat UI" step). The test asserts structure (a ticket row
with real research notes), not exact text — so a failure usually means
something real broke, not LLM mood.

## Running e2e locally

```bash
bash bin/dev               # start the dev stack
cd e2e && npm install && npx playwright install chromium
npm run test:smoke         # 10 seconds, no LLM
npm run test:mock          # needs LLAMABOT_ENABLE_FAKE_LLM=true in .env
npm run test:ticket        # real DeepSeek call, ~3 min, creates+deletes a ticket
```

See `e2e/README.md` for details, env knobs, and side-effect warnings (ticket
mode research writes real files into the working tree).

## Secrets inventory

| Repo | Secret | Used by |
|------|--------|---------|
| Leonardo | `DEEPSEEK_API_KEY` | nightly real-LLM canary |
| LlamaBot | `DOCKERHUB_TOKEN` | release publish |
| LlamaPress-Simple | `DOCKERHUB_TOKEN` | release publish |

## Rules of thumb

- **The tag is the release.** If an image exists on Docker Hub, it went
  through build + boot smoke in CI. Never push images by hand.
- **Leonardo's compose is the source of truth for what prod runs.** Bumping a
  tag there is a PR like any other — CI tests the composition.
- **Green nightly = safe to ship.** Red nightly = fix before deploying
  anything, even if PR CI is green.
