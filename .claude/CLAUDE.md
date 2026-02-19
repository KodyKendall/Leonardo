# Leonardo Starting Project

This is a starting Leonardo project that has a Ruby on Rails application + a starter LangGraph agent already implemented. This is the artifact/deliverable that our coding agent, Leonardo, is iterating on when LlamaBot, which is our FastAPI Uvicorn runtime that runs LangGraph, is running.

This repository is an **overlay codebase** for apps built with the LlamaPress/Leonardo system. It contains only the user-owned parts of a Ruby on Rails project and an AI agent through LangGraph (Python). The Rails **framework skeleton** (Gemfile, bin, boot files, vendor, etc.) lives in the public `llamapress-simple` repo and is bundled into the Docker base image.

The design keeps this repo small, safe for AI-assisted editing, and still easy to "eject" into a normal Rails workflow by combining it with the skeleton.

See the starting rails project and base image here: https://github.com/kodykendall/llamapress-simple

---

## ../LlamaBot implementation (Agent Orchestration) repository & code. 

You can also look in to see how the agent orchestration works for the actual left-hand chat interface implementation, or view the Github Repo at https://github.com/KodyKendall/LlamaBot

The file might exist in `../LlamaBot` `cd ../LlamaBot` (if the user has cloned LlamaBot locally it will be on the filesystem). It's worth checking. It might just be accessed through the docker image in docker-compose.yml though.

## Two Docker Compose Files

| File | Purpose | Rails Source |
|------|---------|--------------|
| `docker-compose.yml` | Production/deployment | Pre-built image `kody06/llamapress-simple:X.X.X` |
| `docker-compose-dev.yml` | Local development | Builds from `../LlamaPress-Simple` |

**Important:** When using `docker-compose-dev.yml`, changes to `LlamaPress-Simple` (like updating `llama_bot_rails`) require rebuilding:
```bash
docker compose -f docker-compose-dev.yml build llamapress
docker compose -f docker-compose-dev.yml up -d llamapress
```

### Hot-reloading the `llama_bot_rails` gem (dev only)

For faster iteration on the gem without rebuilding, `docker-compose-dev.yml` mounts the gem directly:
```yaml
- ../LlamaPress-Simple/vendor/llama_bot_rails:/rails/vendor/llama_bot_rails
```

This means changes to `../LlamaPress-Simple/vendor/llama_bot_rails` are reflected immediately:
- **Views/Controllers**: Rails auto-reloads in development
- **Assets (CSS/JS)**: Restart the server: `docker compose restart llamapress`
- **Migrations**: Run inside the container:
  ```bash
  docker compose exec llamapress bash -c "rails llama_bot_rails:install:migrations && rails db:migrate"
  ```

**Note:** If adding new assets from the gem, you may need to update `rails/app/assets/config/manifest.js`:
```js
//= link llama_bot_rails/application.css
```

---

## Quick Start for Devs:
```
curl -fsSL "https://raw.githubusercontent.com/KodyKendall/Leonardo/refs/heads/main/bin/install/dev" -o install_leonardo_local.sh && bash install_leonardo_local.sh
```

## Quick Start Dev
```
clone your repo
bash bin/dev # this runs docker compose up on the docker-compose-dev.yml file.
open localhost:8000
```

## Repository Layout
```
leonardo/
  docker-compose.yml        # Base compose definition (services, volumes)
  docker-compose.dev.yml    # Local dev overrides
  docker-compose.prod.yml   # Production overrides
  compose.vars              # Tracked env (image refs, flags)
  .env.example              # Secrets template (user fills in .env)

  rails/
    app/                    # Application code (models, controllers, views, jobs)
      javascript/
        application.js      # Main entry point (imports llamapress helpers)
        llamapress/         # LlamaPress-specific helpers (overridable by downstream)
          console_capture.js
          element_selector.js
          message_handler.js
          navigation_tracking.js
      views/layouts/
        application.html.erb
        _llamapress_page_context.html.erb  # Page context script (overridable partial)
    db/                     # Migrations, schema
    config/                 # Safe subset of configs (see below)
    test/ or spec/          # User tests (optional, recommended)

  langgraph/
    agents/                    # User-editable AI agent code
      - leo/                   # Default agent embedded in Rails application
        - nodes.py             # LangGraph agent logic

  scripts/
    eject.sh                # TODO: Build full Rails app from skeleton + overlay
    smoke.sh                # TODO: CI checks using base image
    add-gem.md              # TODO: Human instructions for adding gems

  README.md
```

---

## Config Files Policy

This repo includes only the config files users may reasonably need to edit or carry when ejecting. Access rules are enforced by Docker mounts:

* **Writable (RW)**

  * `config/routes.rb`
  * `config/initializers/llama_bot_rails.rb` (for custom LangGraph integrations)

* **Read-only (RO)**

  * `config/storage.yml` (for S3/local config)
  * `config/environments/*.rb`
  * `config/importmap.rb`
  * `config/puma.rb`
  * `config/cable.yml`
  * `config/initializers/assets.rb`
  * `config/initializers/content_security_policy.rb`
  * `config/initializers/devise.rb` (and other gem initializers)

* **Excluded**

  * `config/database.yml`
  * `config/credentials.yml.enc`
  * `config/master.key`
  * `config/application.rb`, `boot.rb`, `environment.rb` (provided by skeleton)

---

## Guardrails for Leonardo

Leonardo, the AI coding agent, runs in its own container and commits changes via Git. Guardrails:

* **File access** limited by Docker mounts (RW vs RO vs excluded).
* **Git hooks** prevent commits to forbidden files.
* **Prod mounts** are always read-only; redeploy is required to apply changes.

---

## Rails Engine Migrations (llama_bot_rails)

The `llama_bot_rails` gem contains its own migrations. Following [Rails best practices](https://guides.rubyonrails.org/engines.html), we use `install:migrations` to copy them to the app rather than auto-loading from the engine.

**Why this matters:** Auto-loading engine migrations causes `PG::DuplicateTable` errors on downstream forks because migrations get different timestamps and Rails tries to run both versions.

### Workflow for Upstream/Downstream Migration Sync

**In Upstream Leonardo (once per new migration):**
```bash
rails llama_bot_rails:install:migrations
rails db:migrate
git add db/migrate/
git commit -m "Install llama_bot_rails migrations"
```

**In Downstream Forks:**
```bash
git fetch upstream
git merge upstream/main
rails db:migrate
```

That's it. The migrations are already in `db/migrate/` with the correct timestamps, so downstream just runs them like any other migration.

### Why This Works

* **Single source of truth** - Migrations live in Leonardo's `db/migrate/`, not auto-loaded from the engine
* **Consistent timestamps** - Everyone uses the same migration timestamps from upstream
* **schema_migrations stays in sync** - All environments track the same version numbers
* **No duplicates** - The engine does not append its own migration paths

### When You Add New Migrations to llama_bot_rails

1. Add the migration in `vendor/llama_bot_rails/db/migrate/`
2. In Leonardo: `rails llama_bot_rails:install:migrations` (copies new ones only)
3. Commit and push upstream
4. Downstream forks merge and run `rails db:migrate`

**Key insight:** Rails' `install:migrations` only copies migrations that don't already exist in the app, so re-running it is safe and idempotent.

### DO NOT on Downstream Forks

🚫 **DO NOT run `rails llama_bot_rails:install:migrations` on downstream forks.**

This generates new timestamps for engine migrations. If migrations were already installed upstream, running this command locally will:
- Create duplicate migration files with different timestamps
- Cause `PG::DuplicateTable` errors
- Pollute `schema_migrations` with redundant entries

---

## Adding Gems

* Gemfile, Gemfile.lock, bin/, and vendor/ are **not in this repo**.
* They live in the **base skeleton** and Docker image.
* To add a gem:

  1. Clone the `llamapress-simple` repo.
  2. Modify `Gemfile` and run `bundle lock`.
  3. Build and push a new Docker image (`kody06/llamapress-simple:<tag>`).
  4. Update `RAILS_IMAGE_REF` in `compose.vars`.
  5. Commit and redeploy.

Leonardo cannot add gems — only humans can, via the image pipeline.

---

## JavaScript Helpers (llamapress/)

LlamaPress-specific JavaScript is extracted into modular helpers in `rails/app/javascript/llamapress/`. This allows downstream repos to override individual helpers without modifying the main `application.js`.

### Helper Files

| File | Purpose |
|------|---------|
| `console_capture.js` | Captures console.log/error/warn for debugging, persists to sessionStorage |
| `element_selector.js` | Visual element picker for AI to reference specific DOM elements |
| `message_handler.js` | postMessage handling for iframe communication with LlamaBot |
| `navigation_tracking.js` | Turbo navigation events sent to parent iframe |

### How It Works

1. The skeleton (`llamapress-simple`) has `pin_all_from "app/javascript/llamapress", under: "llamapress"` in `config/importmap.rb`
2. Leonardo's `application.js` imports from `llamapress/*`
3. At runtime, Docker mounts overlay Leonardo's JS files onto the skeleton
4. The browser resolves imports to the overlaid files

### Overriding in Downstream Repos

To override a helper, create your own file at the same path:
```
rails/app/javascript/llamapress/console_capture.js
```

Your version will be used instead of upstream's. You can also extend the original by copying and modifying it.

### HTML Partial

The page context script (setting `window.request_path`, `window.view_path`, etc.) is extracted to `_llamapress_page_context.html.erb`. Downstream repos can override this partial to customize page context behavior.

---

## Deployment Philosophy

* **Local dev**: Run `docker compose -f docker-compose.yml -f docker-compose.dev.yml up`. Rails reloads overlay changes; agent reloads with `--reload`.
* **Production**: Run `docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d`. Rails overlay mounted RO; agent runs in hardened container. Deploy by bumping `IMAGE_REF` or pulling new overlay commits.

---

## Reproducibility

Your app is defined by the tuple:

**(Base skeleton/image digest + overlay Git commit)**

This ensures full reproducibility and clear separation of concerns.
