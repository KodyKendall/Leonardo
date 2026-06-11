# Leonardo End-to-End Tests

Playwright tests that drive a **real browser** against the **running Leonardo
stack**: the LlamaBot FastAPI chat UI → WebSocket → LangGraph agents →
`bin/rails runner` → Postgres. The headline test kicks off **ticket mode with a
real LLM call** (DeepSeek v4 Flash) and verifies an implementation-ready ticket
lands in the Rails database.

## What's covered

| Test | LLM | What it proves |
|------|-----|----------------|
| `tests/smoke.spec.ts` | none | Login works, chat UI loads, WebSocket connects, ticket mode + test model are selectable |
| `tests/ticket-mode.spec.ts` | **real** (DeepSeek v4 Flash) | A user observation in ticket mode produces a `llama_bot_rails_tickets` row with a real title, description, and research notes |
| `tests/mock-llm.spec.ts` | mocked (`fake-llm`) | Full browser→agent→UI round trip with zero cost/determinism (opt-in) |

Assertions on LLM-driven flows are **structural** (a ticket row exists, fields
are populated, status is `backlog`) — never exact-text, so normal LLM phrasing
variance doesn't flake the suite.

## Prerequisites

1. The stack is running: `bash bin/dev` (i.e. `docker compose -f docker-compose-dev.yml up -d`)
2. `DEEPSEEK_API_KEY` is set in Leonardo's root `.env` (the llamabot container env)
3. Node 18+ on the machine running the tests

## Setup

```bash
cd e2e
npm install
npx playwright install chromium
cp .env.example .env   # optional — defaults work for local dev
```

## Running

```bash
npm run test:smoke     # fast, no LLM calls
npm run test:ticket    # REAL LLM — creates (then deletes) a ticket; ~2–8 min, a few cents
npm test               # everything (mock test auto-skips unless enabled)
npm run report         # open the HTML report (traces/videos on failure)
```

### Auth

`tests/auth.setup.ts` runs first: it idempotently provisions the test user
(`E2E_USERNAME`/`E2E_PASSWORD`) by exec-ing into the llamabot container and
using LlamaBot's own `user_service`, then logs in through the real `/login`
page and caches the session in `playwright/.auth/user.json`. If the test
runner can't reach the stack via `docker compose` (e.g. testing a remote
host), set `E2E_PROVISION_USER=false` and create the user yourself.

### How the ticket-mode test works

1. Selects **Ticket Mode** + the model from `E2E_LLM_MODEL` in the chat UI
2. Sends a fully-specified observation (email-signup feature on `/welcome`)
   carrying a unique run marker, and asks the agent not to ask follow-ups
3. **Polls Postgres for the ticket row while the agent works** — a
   ticket-mode turn keeps running after the ticket is written (research
   artifacts, spec skeletons), so waiting for the UI to go idle would hang
4. If a turn ends without a ticket (the story-confirmation interrupt), the
   test replies affirmatively, up to 3 rounds
5. Asserts the ticket row exists with substantial title, description
   (>100 chars), research notes, and `backlog` status
6. Deletes the ticket afterwards (set `E2E_KEEP_TICKETS=true` to inspect it)

The Rails database name is auto-detected from the running llamapress
container (`bin/rails runner`), since `database.yml` can map the dev
environment to a non-obvious name. Override with `E2E_RAILS_DB`.

⚠️ **Side effects:** ticket-mode research writes real files into the Leonardo
working tree (spec skeletons — sometimes models and migrations, which it may
run against the dev DB). The test logs everything the agent touched (diff of
`git status`) but deliberately does **not** delete files, since it can't tell
agent artifacts from your uncommitted work. Run against a clean checkout or
disposable environment in CI, and review the logged paths after local runs.

### Mocked-LLM mode

For deterministic, zero-cost plumbing tests, LlamaBot's `llm_factory.py`
supports a `fake-llm` model that returns a fixed response without any API
call. It is double-gated:

1. `LLAMABOT_ENABLE_FAKE_LLM=true` in Leonardo's root `.env`, then restart:
   `docker compose -f docker-compose-dev.yml restart llamabot`
2. `E2E_MOCK_LLM=true` for the test run: `npm run test:mock`

Production deployments never set the flag, so `fake-llm` is unreachable there.

## Configuration

All knobs live in `e2e/.env` (see `.env.example`): base URL, credentials,
compose file, Rails DB name, model, and timeouts. Notably:

- `E2E_BASE_URL` — `http://localhost:8000` for dev compose, `:8080` for prod compose
- `E2E_LLM_MODEL` — any model name `llm_factory.py` understands
- `E2E_TURN_TIMEOUT_MS` / `E2E_TICKET_TIMEOUT_MS` — raise these if research
  turns are slow in your environment

## CI notes

- Run `smoke` on every PR; run `ticket-mode` nightly or pre-release (it costs
  real money and minutes)
- The job needs Docker (to run the stack + DB queries) and `DEEPSEEK_API_KEY`
  as a secret in the stack's `.env`
- `workers: 1` is intentional — the agent stack is stateful; don't parallelize
- On failure, the HTML report contains a full trace + video of the browser
  session (`playwright-report/`)

## Extending

`helpers/chat-page.ts` is a page object over the stable `data-llamabot`
attributes in the chat UI — new agent-mode tests should reuse
`selectAgentMode(...)` + `sendAndWaitForTurn(...)`. `helpers/stack.ts` gives
you `psql(...)` against the Rails DB for verifying any agent side effect
(pages, models, migrations), not just tickets.
