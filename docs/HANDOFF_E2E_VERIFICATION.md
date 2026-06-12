# Handoff Task: Verify the E2E Test & Release Pipeline End-to-End

> **Audience:** a new engineer or a fresh AI agent session with no prior
> context. Everything needed is in this file plus the linked docs.
> **Time:** ~45 min active, ~1.5 h wall clock (CI runs dominate).
> **Cost:** a few cents of DeepSeek API usage (two real-LLM runs).

## The task

Independently verify that every tier of the automated testing and release
pipeline works, end to end, from a clean state — local tests, PR gates, the
cross-repo integration job, the nightly real-LLM canary, and the gated image
release. The pipeline was built and verified green on 2026-06-11; this task
re-proves it (e.g. after significant changes, onboarding, or suspicion of
drift).

**Acceptance criteria — all of these observed personally, not assumed:**

- [ ] A1. Local smoke suite passes against the dev stack
- [ ] A2. Local mock-LLM test passes (fake-llm, zero API cost)
- [ ] A3. Local real-LLM ticket-mode test passes and the ticket is verifiably
      in Postgres (test prints `ticket #N`), then cleaned up
- [ ] A4. Leonardo PR CI runs lint + RSpec + e2e-smoke and goes green
- [ ] A5. LlamaBot CI on a `*-alpha` push runs pytest + the e2e job
      (commit's image inside Leonardo's stack) and goes green
- [ ] A6. Nightly workflow passes via manual dispatch (real DeepSeek call)
- [ ] A7. LlamaBot release workflow publishes an `-rc` image to Docker Hub
      after its boot smoke (or completes a dry run, see B4)
- [ ] A8. The failure path works: a deliberately broken run produces a
      Playwright report artifact with video/trace (and, for the nightly, a
      GitHub issue)

## Context map (read first, ~10 min)

| Doc | What it covers |
|-----|----------------|
| [SHIPPING.md](SHIPPING.md) | The pipeline: which workflow runs where, release-by-tag flow |
| [TESTING.md](TESTING.md) | Testing philosophy: what we test, structural-not-textual LLM assertions |
| [`e2e/README.md`](../e2e/README.md) | The Playwright suite itself: tiers, env knobs, side-effect warnings |

Repos: `KodyKendall/Leonardo` (this repo — composition + e2e suite),
`KodyKendall/LlamaBot` (agents/chat UI; dev branch is `*-alpha`, e.g.
`0.4.1-alpha`), `KodyKendall/LlamaPress-Simple` (Rails skeleton image).

Secrets that must exist (Settings → Secrets → Actions): `DEEPSEEK_API_KEY`
on Leonardo; `DOCKERHUB_TOKEN` on LlamaBot and LlamaPress-Simple.

## Part A — Local verification (~20 min)

Prereqs: Docker Desktop running; Node 18+; sibling checkouts
`../LlamaBot` and `../LlamaPress-Simple`; a real `DEEPSEEK_API_KEY` in
Leonardo's `.env` (copy from `.env.example` and fill in).

```bash
# 1. Start the dev stack and wait for it
bash bin/dev                      # or: docker compose -f docker-compose-dev.yml up -d
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8000/login   # expect 200 or 302

# 2. Install the test harness
cd e2e && npm install && npx playwright install chromium

# 3. Tier 1 — smoke (no LLM, ~10s)                       → acceptance A1
npm run test:smoke

# 4. Tier 2 — mock LLM (zero cost, deterministic)        → acceptance A2
grep LLAMABOT_ENABLE_FAKE_LLM ../.env   # must be 'true'; if you add it, run:
#   docker compose -f docker-compose-dev.yml up -d llamabot   (restart does NOT reload env!)
npm run test:mock

# 5. Tier 3 — real LLM (~3 min, a few cents)             → acceptance A3
npm run test:ticket
# PASS looks like: "[ticket-mode] ticket #N: '...'" then 1 passed.
# The test deletes its ticket; set E2E_KEEP_TICKETS=true to inspect it first.
```

After step 5, check what the agent touched: the test logs any working-tree
changes it made (ticket-mode research can write spec files, even
models/migrations). Review `git status` and discard anything you don't want.

## Part B — CI verification (~25 min active)

### B1. Leonardo PR gate → acceptance A4

```bash
git checkout -b verify/e2e-pipeline
git commit --allow-empty -m "verify: exercise CI pipeline"
git push -u origin verify/e2e-pipeline
gh pr create --title "verify: e2e pipeline" --body "Exercising CI; will close."
gh pr checks --watch     # expect: ERB Lint ✓, RSpec ✓, E2E Smoke ✓ (~8 min)
```

Close the PR and delete the branch afterwards.

### B2. LlamaBot integration gate → acceptance A5

```bash
cd ../LlamaBot && git checkout 0.4.1-alpha   # or the current *-alpha branch
git commit --allow-empty -m "verify: exercise CI pipeline" && git push
gh run watch $(gh run list --branch 0.4.1-alpha --limit 1 --json databaseId --jq '.[0].databaseId')
# expect BOTH jobs green: "test" (pytest) and "E2E vs Leonardo stack (mock LLM)"
```

Note: the e2e job checks out Leonardo **main** — if you changed the e2e suite,
merge that to Leonardo main first.

### B3. Nightly canary on demand → acceptance A6

```bash
gh workflow run e2e-nightly.yml -R KodyKendall/Leonardo
gh run watch $(gh run list -R KodyKendall/Leonardo --workflow e2e-nightly.yml --limit 1 --json databaseId --jq '.[0].databaseId')
# expect: smoke ✓ then "Ticket mode with real DeepSeek" ✓ (~15 min total)
```

Also confirm the schedule is registered:
`gh workflow view e2e-nightly.yml -R KodyKendall/Leonardo` → cron `0 12 * * *`, state active.

### B4. Release pipeline → acceptance A7

Cheapest full proof — publish a throwaway release candidate:

```bash
cd ../LlamaBot
git tag v<next-version>-rc1 && git push origin v<next-version>-rc1
gh run watch $(gh run list --workflow Release --limit 1 --json databaseId --jq '.[0].databaseId')
# expect: build → "Smoke test - boot container" ✓ → multi-arch push (~20-30 min)
curl -s https://hub.docker.com/v2/repositories/kody06/llamabot/tags/<next-version>-rc1 | jq .name
```

Clean up: `git push --delete origin v<next-version>-rc1` (the Docker Hub rc
tag is harmless; delete it in the Hub UI if you care).

If the release workflow file is on the repo's **default branch**, a no-push
variant exists instead: Actions → Release → Run workflow → `dry_run: true`.
(As of this writing it lives only on `0.4.1-alpha`, so the rc-tag route is
the one that works.)

### B5. Failure path → acceptance A8

Pick either:
- Temporarily break a selector in `e2e/tests/smoke.spec.ts` on a branch, push,
  and confirm the failed run has a `playwright-report-smoke` artifact
  containing video + trace. Revert.
- Or wait for any real nightly failure and confirm a GitHub issue titled
  "Nightly e2e (real LLM) failed — <date>" appears with a link to the run.

## Known gotchas (cost real debugging time — don't relearn them)

1. **`/login` returns 302 on a fresh instance** (zero users → redirect to
   `/register`). Health checks accept 200 *or* 302. If you write a new check,
   do the same.
2. **`GOOGLE_API_KEY` must be set even if unused** (placeholder ok). Agent
   graphs instantiate the Gemini client at startup; entirely-unset →
   compilation fails → chat is silently dead. `.env.example` includes it now.
3. **`docker compose restart` does NOT reload `env_file`.** New env vars need
   `docker compose up -d <service>` (recreate).
4. **The Rails dev environment writes to `llamapress_production`** (yes,
   really — see `rails/config/database.yml`). The e2e suite auto-detects this
   via `bin/rails runner`; don't hardcode DB names.
5. **CI must create the `llamabot_production` database** — the postgres image
   only creates `POSTGRES_DB`. All workflows already do this.
6. **`workflow_dispatch` buttons only appear for workflows on the default
   branch.** Tag triggers work from any ref.
7. **Ticket-mode research has real side effects** — it can write specs,
   models, and run migrations against the dev DB. Fine in CI (throwaway),
   reviewable locally (the test logs what was touched, deletes nothing).

## Sign-off

When all eight boxes are checked, the pipeline is verified. Record the date
and any new gotchas you hit — per the META rule in `.claude/CLAUDE.md`,
update this doc / TESTING.md / project memory rather than letting the lesson
evaporate.

| Date | Verified by | Notes |
|------|-------------|-------|
| 2026-06-11 | Claude + Kody (initial build) | All tiers green; rc3 published |
