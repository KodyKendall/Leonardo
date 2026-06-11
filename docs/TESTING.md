# Testing Philosophy

How we decide what to test, when to write the test, and what "tested" means
here. Companion to [SHIPPING.md](SHIPPING.md), which covers the CI/CD
pipeline that enforces all of this.

## The headline rules

1. **The pipeline is the gate, not a human.** PR CI (specs + pytest + browser
   smoke + mock-LLM e2e) decides whether code merges. The nightly real-LLM
   canary decides whether it's safe to ship. Manual testing is for
   *exploration* — does this feel right, is the UX good — never for
   verification. No one should ever be the human regression suite.
2. **Bug fix = failing test first. No exceptions.** Reproduce the bug as a
   failing spec/pytest *before* fixing it. The reproduction is work you do
   anyway while debugging; the test is nearly free once you have it. This is
   the one rule that must never decay: it only triggers when reality has
   already proven a test was missing, so the suite grows into a map of
   everything that has ever actually bitten us.
3. **Test-first when delegating to an AI agent.** A failing test is the most
   precise, cheapest-to-verify prompt there is. The workflow:
   **ticket → failing spec → agent implements until green → e2e smoke
   confirms → ship.** Review the contract (the test), not every line.
   Ticket mode already emits test plans with spec recommendations — use them.

## Where test-first applies (and where it doesn't)

| Zone | Approach | Why |
|------|----------|-----|
| Bug fixes | **Test first, always** | See rule 2 — highest-ROI testing habit that exists |
| Code an AI agent will write | **Test first** | The test is the spec the agent iterates against |
| Deterministic logic with a clear contract (Rails models, validations, business rules; FastAPI auth/tokens, WS routing, interrupt handling) | Test first when the spec is clear; test-soon (backfill once the shape settles) when still exploring | TDD pays off when you know what "done" means before you start |
| Prompts and agent behavior | **No unit TDD.** Structural e2e assertions (real-LLM nightly + fake-llm tier), evals if prompt quality becomes recurring pain | You can't red-green-refactor a system prompt; exact-output assertions on LLMs produce permanently flaky tests that teach you to ignore failures |
| UI / visual work | Test-after: Playwright smoke on load-bearing flows. Add `data-llamabot`/`data-testid` attributes as you build | The cheap discipline is keeping flows *testable*, not TDD'ing pixels |

## Testing LLM behavior specifically

- Assert **structure, not text**: a ticket row exists, fields are populated,
  the interrupt fired, status is `backlog`. Never assert exact LLM phrasing.
- Run real-LLM tests at **low frequency** (nightly + on-demand), with the
  cheap deterministic `fake-llm` tier covering the plumbing on every PR.
  See `e2e/README.md`.
- If prompt regressions become a recurring pain, the next step is a small
  eval set (5–10 canned scenarios scored structurally) — not unit tests.

## Definition of done for a feature

- Specs/pytest pass for any deterministic logic it added.
- E2E smoke passes (CI enforces this).
- If it touched an agent flow: the e2e suite was extended, or we consciously
  decided not to (say so in the PR).
- If it fixed a bug: the regression test exists and failed before the fix.

## What we deliberately don't do

- Dogmatic red-green-refactor for everything. Much of this codebase (prompts,
  agent orchestration, chat UI) lacks the deterministic spec TDD needs, and
  forcing it there produces ceremony, not safety.
- Exact-text assertions on anything an LLM generates.
- Manual pre-deploy click-throughs as a gate. The on-demand nightly workflow
  button (Actions → "E2E Nightly (real LLM)") replaces founder heroics.
