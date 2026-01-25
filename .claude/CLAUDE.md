# Leonardo Starting Project

This is a starting Leonardo project that has a Ruby on Rails application + a starter LangGraph agent already implemented. This is the artifact/deliverable that our coding agent, Leonardo, is iterating on when LlamaBot, which is our FastAPI Uvicorn runtime that runs LangGraph, is running.

This repository is an **overlay codebase** for apps built with the LlamaPress/Leonardo system. It contains only the user-owned parts of a Ruby on Rails project and an AI agent through LangGraph (Python). The Rails **framework skeleton** (Gemfile, bin, boot files, vendor, etc.) lives in the public `llamapress-simple` repo and is bundled into the Docker base image.

The design keeps this repo small, safe for AI-assisted editing, and still easy to "eject" into a normal Rails workflow by combining it with the skeleton.

See the starting rails project and base image here: https://github.com/kodykendall/llamapress-simple

---

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

## Deployment Philosophy

* **Local dev**: Run `docker compose -f docker-compose.yml -f docker-compose.dev.yml up`. Rails reloads overlay changes; agent reloads with `--reload`.
* **Production**: Run `docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d`. Rails overlay mounted RO; agent runs in hardened container. Deploy by bumping `IMAGE_REF` or pulling new overlay commits.

---

## Reproducibility

Your app is defined by the tuple:

**(Base skeleton/image digest + overlay Git commit)**

This ensures full reproducibility and clear separation of concerns.
