# Distribution & Ownership — how updates reach forked Leonardo instances

**Status:** Architecture reference. Describes how the Leonardo overlay ships updates to the
apps forked from it, who owns which files, and how those two things are kept from colliding.

> **The one idea.** For an *existing* app, upstream is **default-block**: nothing arrives over
> a `git merge` — ever. Instead, an explicit **allowlist** of platform paths is pulled wholesale
> with `git checkout upstream/main -- <allowlist>`, and the runtime ships as versioned Docker
> images. Everything not on the allowlist is the client's, untouched. The allowlist starts tiny
> and is meant to trend toward **zero** as platform code moves into the image.

---

## 1. The setup

- This repo (`Leonardo`) is the **upstream open-source overlay**. It contains only the
  user-owned parts of a Rails app plus a LangGraph agent. The Rails skeleton, `Gemfile`,
  `vendor/`, and the LlamaBot runtime live in Docker images
  (`kody06/llamapress-simple:X`, `kody06/llamabot:X`), **not** in this repo.
- **Every client app is a fork** of this repo with an `upstream` remote pointing here. An app
  is born by baking an LXC image containing a fresh checkout of this overlay with `upstream`
  pre-configured. So **app creation = a snapshot of upstream at bake time.**
- Two update channels exist for an already-running app:

  | Channel | Carries | How |
  |---|---|---|
  | **Image** | the LlamaBot + Rails runtime, the gem, framework JS, agent code, base layouts | `bin/update <llamabot_ver> <llamapress_ver>` — swaps image tags, **no `git pull`** |
  | **Allowlist pull** | an explicit set of platform paths (starts at migrations + tooling) | `git fetch upstream && git checkout upstream/main -- <allowlist> && rails db:migrate` |

  The image channel is clean — no merge, no conflicts. The allowlist pull replaces what used to
  be a `git merge upstream/main`.

## 2. Why not `git merge`

The original distribution mechanism was `git merge upstream/main`. The root problem:

> We were using a **textual 3-way merge as the distribution mechanism for what is actually a
> layered system.**

Git merge has no concept of *ownership*. It cannot distinguish platform code the client must
take wholesale, from client-owned code the platform must never touch, from per-instance state
that belongs in neither shared history. Its one safety mechanism — conflict markers — fires
only on *textual* overlap. The dangerous case is the **non-conflicting silent edit**: upstream
changes a file the client also owns, but in a different region, so the merge applies clean and
silently alters the client's app with no marker to review.

**Failure modes this produced** (generalized; each is a real class of incident):

- A non-conflicting merge **silently disabled authentication** in a client-owned controller.
- An upstream content block was **injected into a client-owned view** with no conflict.
- A client's **root route was reverted** by an upstream change to routing config.
- Recurring **image-tag conflicts** because the pin lived inline in a client-edited compose file.
- A **per-instance state file tracked in a fork** drifted in git history and pointed an instance
  at the **wrong backup storage bucket**.

Every one of these is the same root cause: platform, client, and instance-state concerns sharing
one git history with a merge as the only gate.

## 3. The five ownership tiers

Make ownership **explicit and structural** so both humans and tooling can enforce it. Every
tracked path belongs to exactly one tier; the tier decides which channel updates travel and
whether a merge may ever change the file.

| Tier | Who owns it | How updates reach an existing client | May a merge change it? |
|---|---|---|---|
| **PLATFORM** | upstream | image (`bin/update`) or fresh bake; allowlist pull for the enabled subset | only `rails/db/migrate` (see note) |
| **PLATFORM-OVERRIDABLE** | upstream owns canonical; client may shadow | image; a client override is an opt-in | no — upstream never merges into an override |
| **APP** | client (seeded once at bake) | client edits directly; **upstream never touches** | should be **zero** incoming changes |
| **DERIVED** | nobody — generated | regenerated locally | no — `merge=ours`, then regenerate |
| **INSTANCE STATE** | the instance | written per-deploy; gitignored | n/a — not tracked |

**Two rules make it enforceable:**

1. **Most-specific glob wins** (CODEOWNERS-style). `bin/**` is PLATFORM, but the more-specific
   `bin/local/**` is APP. A carve-out always beats its parent.
2. **Exhaustive.** Every tracked path matches a tier; an unclassified path is a smell to resolve.

**The keystone invariant:** upstream must not modify any **APP** path. Every silent breakage above
was upstream reaching into the APP tier. If upstream never touches those paths, there are no
surprises to merge.

## 4. Path-by-path ownership

### PLATFORM — upstream owns, client takes wholesale

| Glob | Note |
|---|---|
| `bin/**` | tooling. Carve-out: `bin/local/**` is APP |
| `e2e/**` | test harness |
| `rails/db/migrate/**` | **The one PLATFORM path that travels by merge/pull.** Append-only, unique timestamps → near-zero textual conflict. Authored upstream via `install:migrations`; never auto-loaded from the engine (auto-loading causes duplicate-table errors on forks). Clients never hand-edit. |
| `docker-compose.yml`, `docker-compose-dev.yml` | base composition. Image tags should be `${VAR}`-interpolated from `.env` so they stop conflicting. Client extras go in `docker-compose.override.yml` (APP). |
| `instance-template.json` | the template; the rendered `.leonardo/instance.json` is INSTANCE STATE |
| `.github/workflows/_platform-*.yml` | reusable workflows the client's thin `ci.yml` calls |

### PLATFORM-OVERRIDABLE — upstream owns the canonical copy; client may shadow

Canonical copy should live in the **skeleton image**; a same-path file in this overlay wins at
runtime (importmap `pin_all_from` + the Docker mount). An override is a deliberate opt-in —
upstream ships improvements to the canonical copy via the image and **never merges into a
client's override**.

| Glob | Note |
|---|---|
| `rails/app/javascript/llamapress/**` | **The iframe protocol** (element selector, console capture, nav tracking, postMessage). One half of a contract whose other half ships in the LlamaBot image — must version in lockstep. Today these live only in the overlay; the target is to move the canonical copies into the skeleton image (see §8). |
| `rails/app/views/layouts/_llamapress_page_context.html.erb` | sets `window.request_path` / `view_path` / `full_html` — how the agent knows what page it is looking at. Same protocol, same treatment. |
| `langgraph/**` | the agent layer (`leo`, custom agents, `langgraph.json`). **Open decision:** strictly PLATFORM (clients never edit their agent) vs PLATFORM-OVERRIDABLE (clients may customize, default `leo` is a seed). Currently left off the allowlist, i.e. effectively client-owned/seeded. |
| `rails/config/environments/*.rb` | framework env config. `development.rb` carries the dev error-page middleware — **env-gate it** so it stops being a manual merge and never reaches client production. |
| `rails/config/importmap.rb`, `rails/config/puma.rb`, `rails/config/cable.yml`, `rails/config/storage.yml` | framework wiring |
| `rails/config/initializers/pagy.rb`, `paper_trail.rb`, `rack_attack.rb` | framework-default initializers (not auth) |
| `rails/app/assets/config/manifest.js` | asset link manifest |

### APP — client owns; upstream never edits after the bake

Seeded once at the bake; thereafter the client's. Upstream improvements reach **new** apps via
the next bake, **never** via merge into an existing app.

| Glob | Note |
|---|---|
| `rails/app/views/**` | their pages/layouts (`home`, `prototypes`, `application.html.erb`, favicons-in-layouts). Exception: the platform partial above (more-specific glob). |
| `rails/app/controllers/**` | incl. `application_controller.rb` (the auth-skip failure mode), `api/**`, `admin/**` |
| `rails/app/javascript/**` | their JS (`application.js`, `controllers/**`). Exception: `llamapress/**` above. |
| `rails/app/assets/**` | branding, stylesheets, images. Exception: `builds/**` (DERIVED) and `manifest.js` (above). |
| `rails/config/routes.rb` | the root-route-revert failure mode lived here |
| `rails/config/initializers/devise.rb` | auth config — clients customize |
| `rails/config/initializers/llama_bot_rails.rb` | custom LangGraph integration (if present) |
| `.leonardo/LEONARDO.md`, `.leonardo/BOOTSTRAP*.md` | the client's Leo instructions |
| `bin/local/**` | bespoke client scripts. Platform never ships here. See §7. |
| `docker-compose.override.yml` | client's extra services/overrides (compose auto-merges it) |
| `.github/workflows/ci.yml`, `.github/workflows/e2e-nightly.yml` | thin client wrappers. Tune branches here; platform logic belongs in `_platform-*.yml`. |
| `README.md`, `AGENTS.md` | client-facing docs |

### DERIVED — generated, never merged

| Glob | Note |
|---|---|
| `rails/db/schema.rb` | `.gitattributes: merge=ours`; regenerate after migrating. The recurring schema conflict disappears once this lands. |
| `rails/app/assets/builds/**` | compiled assets |

### INSTANCE STATE — gitignored, never tracked

| Glob | Note |
|---|---|
| `.env`, `.env.*` | secrets + the interpolated image tags `bin/update` writes |
| `.leonardo/instance.json` | per-instance identity / backup target. The **wrong-bucket** failure mode was this file tracked in a fork. Ship the ignore so forks inherit it. |
| `.leonardo/last_update.json`, `.leonardo/update.log` | `bin/update` runtime markers |

## 5. The allowlist mechanism

For an existing app, **default-block**: the only platform content that crosses into the fork is
the explicit allowlist, pulled wholesale.

```
bin/update <llamabot_ver> <llamapress_ver>   # sync allowlist + swap images + restart
bin/update --sync-only                        # just pull the allowlist, no image swap
```

The list lives in `bin/update` (the `ALLOWLIST` array). Because `bin/` is itself on the list,
the allowlist is upstream-controlled and **self-updating** — a future addition ships itself.

**v1 allowlist** (the smallest self-sustaining set):

```
bin               # platform tooling, incl. bin/update itself => the allowlist self-propagates
rails/db/migrate  # new platform migrations (append-only; never collides with the app's own)
```

Two files get special handling (not a wholesale checkout):

- `.gitignore` is **union-merged** (upstream lines appended, client lines kept) — never overwritten.
- `.leonardo/instance.json` is **force-untracked** (`git rm --cached`) and ignored.

The sync is committed scoped to these paths only, and is **guarded**: if it finds unrelated staged
work (the agent mid-edit) it leaves the sync staged and refuses to commit. It skips gracefully when
there is no `upstream` remote (e.g. on the upstream repo itself).

### Why it is safe

> `git checkout <ref> -- <path>` is an **unconditional overwrite** of paths present in the ref —
> not a merge. It stamps upstream's version onto those paths with no conflict detection, and it
> **never deletes** working-tree files that are not in the ref.

Consequences:

- A path may join the allowlist **only if clients never edit files in it.** The moment a client
  edits an allowlisted file, the next pull silently wipes their change — the exact failure we are
  killing, in reverse. The allowlist's ceiling is therefore the **PLATFORM tier**; each addition
  is a deliberate transfer of ownership.
- It is still safe for files the app *also* has (e.g. migrations): checkout only overwrites paths
  that exist in upstream, so an app keeps every migration it authored (unique timestamps → no
  collision) and gains upstream's new ones. The only thing that could be clobbered is a same-named
  file the app edited — which for migrations you never do (they are immutable once shipped; schema
  changes get a *new* migration).

### The deliberate tradeoff

An upstream *fix* to an app-seed file (e.g. a bug in `home.html.erb`) will **not** auto-reach
existing apps — those files are the client's now. If a fix must reach everyone, it belongs in the
**image** (ships via `bin/update`), goes on the **allowlist** (only if it is truly platform), or
is applied per-app deliberately. Never silently merged. This is the point, not a gap.

One caveat: checkout adds/overwrites but never **deletes**, so if upstream removes a platform file
it lingers downstream — harmless for now; revisit only if it ever matters.

## 6. Seed vs. sync — why the bake makes this easy

Most APP-tier files are **seeds**: written once when the app is born, then client-owned forever
(`home.html.erb`, the root route, `application_controller` auth, `devise.rb`, `.leonardo/LEONARDO.md`,
branding). **The LXC image bake _is_ the seed event** — a client app is a snapshot of upstream at
bake time. Therefore:

- Improvements to seed defaults reach **new apps** automatically via the next bake.
- They must **never** reach **existing apps** via merge — that is exactly the silent-breakage class.
- The only update channels into an *existing* app are `bin/update` (runtime/images) and the narrow
  allowlist pull (migrations + tooling).

This is why "upstream never edits APP-tier files" is not a limitation — it is the design.

## 7. Extension points (clients have legitimate platform-file needs)

Divergence on platform files is handled by **layering**, not by editing the pristine file:

- **CI:** platform ships a reusable workflow (`_platform-ci.yml`); each app's thin `ci.yml` calls it
  and adds client-specific jobs/branches. Upstream evolves the reusable workflow; the client file
  rarely conflicts.
- **Compose:** platform `docker-compose.yml` (image tags parametrized to `${VAR}`) + a client
  `docker-compose.override.yml` (Compose merges multiple `-f` files).
- **Tooling:** prefer **config-driven backends** over forking a script. An ops *destination* (e.g.
  a backup target, or which cloud's object store to use) is **data, not code** — platform scripts
  read the backend + target from instance state and dispatch, so "this client uses a different
  backend" is one config value with zero script divergence. For genuinely bespoke logic, reserve an
  APP-owned `bin/local/**` namespace; platform never ships there. Optionally, platform scripts may
  source `bin/local/hooks/<event>.sh` *if present*, letting a client inject a step without editing
  the platform script.

## 8. The iframe protocol contract belongs in the image

The browser tooling that lets the agent "see" the app — the visual element selector, console
capture, navigation tracking, screenshots, and the `_llamapress_page_context.html.erb` partial that
sets `window.request_path` / `view_path` / `full_html` — is **one half of a postMessage protocol.**
The other half (the parent chat UI) ships in the **LlamaBot image**. Messages are tagged with a
`source` and typed payloads; both ends must agree.

**The problem: the two halves ship through different channels.** LlamaBot's half ships via image
(`bin/update`); the Rails half lives **only in this overlay** — the skeleton has the importmap
`pin_all_from` pin but not the files. So the Rails half historically reached clients only via merge.
A protocol change on the image side against a stale or client-overridden overlay copy **silently
breaks** element selection and page context, with no conflict marker.

**The fix: ship both halves through the same channel — the image.** Move the canonical
`llamapress/*` JS + the page-context partial **into the LlamaPress-Simple skeleton** (baked into
`kody06/llamapress-simple:X`). The importmap pin is already there; only the files move. Then they
version in lockstep with the LlamaBot side, reach clients via `bin/update` (never merge), become
**PLATFORM-OVERRIDABLE** (a client may still drop a same-path override), and leave the merge surface
entirely. The page-context partial already exposes `appVersion` — the natural place to stamp a
protocol version if a runtime compatibility check is ever wanted.

## 9. What legitimately flows upstream → existing app

After the split, only this should cross into an existing app:

- **Image tag bumps** → moved to one interpolated var read from `.env`
  (`image: kody06/llamabot:${LLAMABOT_VERSION:-...}`). `bin/update` already supports this exact
  mode (writes the version into gitignored `.env`, keeps the tracked file clean), which removes the
  compose file from the conflict surface permanently.
- **New engine DB migrations** → the lowest-risk path is to keep them flowing via the allowlist
  pull. They are the lowest-conflict surface (unique timestamps never textually collide). Do **not**
  switch to auto-loading engine migrations or running them from the image at boot — that caused
  duplicate-table errors on forks. `schema.rb` becomes `merge=ours` + regenerate, so the one file
  that *does* conflict no longer does.
- **New additive framework files** (a new JS helper, a new middleware) → additive, conflicts rare.

## 10. The dev error-page middleware (the one genuine env-config merge)

The Leonardo error page ("Ask Leo to Fix") is wanted in the platform's own development environment
but **not** in client production. Fix: **env-gate it** in platform code —
`config.middleware.insert_after(...)` guarded by e.g. `ENV["LEONARDO_DEV_ERROR_PAGE"] == "1"`,
default off in prod. Then `development.rb` stops needing a manual merge, the feature stays in dev,
and client production never gets it.

## 11. The second axis — what the Leo agent may write

Ownership (who controls a file, how it propagates) is **orthogonal** to *what the Leo agent may
edit*. Leo's write-scope is set by two levers the platform controls — **which overlays are mounted
read-write into the `llamabot` container** and the **tool-prompt descriptions** — not by a sandbox.
(Leo only writes through the file-edit tools exposed to it; this is a steering concern, not a
threat-model one.) Privilege hierarchy: **platform ⊇ human-client ⊇ Leo.**

| Tier | Leo access | Why |
|---|---|---|
| **APP** | **read-write** | the app Leo builds — its whole job |
| **PLATFORM** | read-only | arrives via image; editing the overlay copy fights upstream |
| **PLATFORM-OVERRIDABLE** | read-only | an override is a human's deliberate opt-in, not Leo's |
| **DERIVED** | regenerate-only | never hand-edit `schema.rb`; produce it by running a migration |
| **INSTANCE STATE** | **read-only** | `.env` / `instance.json` are deploy config + secrets, not app code — the one thing a human may change that Leo must not |

**Auth & routing stay Leo-writable.** `routes.rb`, `devise.rb`, and the auth parts of
`application_controller.rb` are APP-tier and remain read-write for Leo — even though they are
exactly the silent-breakage cases — because the backstop is the **approval gate** (Leo never ships
autonomously; a human reviews the diff), not a mount lock. Locking them would block legitimate
app-building.

**Enforcement is target-state.** Today `llamabot` mounts the *whole repo* read-write (for git
access) plus `.leonardo` read-write, so Leo can currently write everything. Narrowing those mounts
— mount the APP overlays read-write and the rest read-only, without breaking git's need for a
writable working tree — is the remaining work.

## 12. Phased migration plan (mechanism only)

Two risks set the order: (a) a **bootstrap chicken-and-egg** — existing clients run the *old*
`bin/update` with no sync, so `bin/` must be on the allowlist from v1 and a one-time bootstrap must
install the first synced `bin/update`; (b) **wholesale-overwrite divergence** — a path's first sync
overwrites it on the fork, so fork divergence must be audited before a path joins the allowlist.

- **Phase 0 — land the mechanism.** Trim the v1 allowlist to `bin` + `rails/db/migrate`; implement
  the sync in `bin/update` (`--sync-only`, `.gitignore` union-merge, `instance.json` untrack,
  guarded scoped commit); add a regression test and a fast CI job; parametrize compose image tags
  and add `.gitattributes` (`schema.rb merge=ours`).
- **Phase 1 — prove on one real fork, then bootstrap.** Enumerate live forks; exercise
  `bin/update --sync-only` on one staging fork (migrations pull, app untouched, scoped commit
  lands); define and prove the one-time bootstrap that delivers the first new `bin/update` to
  existing forks. After this, updates are self-sustaining.
- **Phase 2 — grow the allowlist, one path at a time (audit-gated).** For each Phase-2 target
  (`docker-compose.yml`, `rails/app/javascript/llamapress`, the page-context partial): divergence-
  audit across forks, move any real client customization out of the path (compose extras →
  override file; bespoke scripts → `bin/local/`; intentional JS tweaks → a deliberate same-path
  override), then add the path and let it propagate.
- **Phase 3 — trend the allowlist toward zero.** Move the iframe protocol JS + page-context partial
  into the skeleton image so both halves ship via image, then remove them from the allowlist
  (image delivery > allowlist pull). Resolve the parked decisions below.

## 13. Open questions / parked decisions

- **`langgraph/**` ownership** — strictly PLATFORM (clients never edit their agent) vs
  PLATFORM-OVERRIDABLE (clients may customize, default `leo` is a seed). Currently left off the
  allowlist, i.e. effectively client-owned/seeded.
- **`rails/config/database.yml`** — tracked here but the config policy lists it as excluded;
  decide whether to untrack it (INSTANCE STATE) or formally adopt it as APP.
- **Compose image-tag parametrization** into `.env` so the tracked compose file carries no tags.
- **Whether to auto-commit the sync on clients** (currently yes, scoped + guarded) — revisit if it
  ever surprises anyone.
- **Mount-narrowing without breaking git** — the whole-repo read-write mount exists for git access,
  but git needs a writable working tree; how to scope Leo's writes without losing that.
- **Heavier enforcement** (a CODEOWNERS-style manifest, an upstream CI guard that fails PRs touching
  an APP path, a client-side audited-merge tool) was considered but is **not pursued** — the
  default-block allowlist makes it unnecessary. Build it only if a specific pain demands it.
