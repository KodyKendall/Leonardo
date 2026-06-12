# QA Staging: the `candidate` branch gate

**Status:** Active — mothership half built by Mother Leo; Leonardo half is the
`candidate` branch + the `ci.yml` trigger below.
**Companion docs:** [SHIPPING.md](SHIPPING.md), [TESTING.md](TESTING.md)

## The idea

Philosophy is unchanged: **merge to Leonardo `main` = live for the fleet.** This
adds a QA gate *in front of* `main` so we catch "does this exact tuple even spin
up on a real VM" before customers do — the things GitHub Actions can't exercise
(real node, real two-layer Caddy/TLS, real provisioning path).

The deploy tuple is just **Leonardo `main` HEAD**: its `docker-compose.yml` pins
the image tags and the repo itself is the overlay, so the whole tuple collapses
to one git commit.

## Two halves, who owns what

**Mother Leo owns the infrastructure (we never touch this):**
- A QA LXD container on the `lxd4` node, pinned to the **`candidate`** branch
  (not `main`).
- A "Run QA" action that hard-resets that box to the candidate tip, runs
  `docker compose pull && up -d`, and health-probes the real public URLs.
  Results land in the mothership admin **Job Runs** feed (pass/fail + the tuple).
- The QA VM, DNS/Caddy/TLS, secrets. She never pushes to this repo.

**We own the Leonardo repo (`KodyKendall/Leonardo` — the repo the fleet clones):**
- The long-lived `candidate` branch, the `ci.yml` edit, landing updates, cutting
  image tags, and the promote PR. We never touch prod infra.

> "Leonardo repo" = `KodyKendall/Leonardo` (cloned by every fleet instance;
> `~/dev/Leonardo` on the dev box). Distinct from the mothership app Mother Leo
> runs.

## The branch model

`candidate` is a **single long-lived branch parallel to `main`** — not a
branch-per-change. All updates land on `candidate` first; nothing goes straight
to `main`.

`ci.yml` knows about `candidate` on both triggers, so candidate work gets the
same ERB-lint + RSpec + e2e-smoke gate as `main`:

```yaml
on:
  push:
    branches: [main, master, candidate]
  pull_request:
    branches: [main, master, candidate]
```

`e2e-nightly.yml` is unchanged — it has `workflow_dispatch`, so the real-DeepSeek
canary can be run against `candidate` from the Actions tab on demand.

## How to land an update (pick the sub-flow)

- **Overlay-only** — a Rails app change, a langgraph agent change, or bumping a
  `docker-compose.yml` tag to an **already-published** image → **PR it into
  `candidate`.**
- **Needs a new image** — a LlamaBot or LlamaPress-Simple *code* change → first
  cut the image the normal way via that repo's tag release
  (`git tag vX.Y.Z && git push origin vX.Y.Z` → publishes `kody06/...:X.Y.Z`),
  **then** bump that tag in Leonardo's `docker-compose.yml` on `candidate`. The
  image `release.yml` workflows don't change.

## The loop

```
land on candidate
  → CI runs against candidate (lint + RSpec + e2e-smoke)
  → ping Mother Leo / Kody to "Run QA" on the lxd4 box
  → if CI green AND the QA box boots green
      → open PR: candidate → main, merge
        (merge to main = fleet-live, exactly like today)
```

## References

- `docker-compose.yml` — the pinned prod composition; the tuple lives here
- `.github/workflows/ci.yml` — gates `candidate` and `main`
- `bin/install/prod` — the production installer the QA box exercises
- [SHIPPING.md](SHIPPING.md) — the release pipeline this gate sits in front of
