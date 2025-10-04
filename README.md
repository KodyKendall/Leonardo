# Leonardo Starting Project

This is a starting Leonardo project that has a Rails application + a starter LangGraph agent already implemented. This is the artifact/deliverable that our coding agent, Leonardo, is iterating on when LlamaBot is running.

This repository is an **overlay codebase** for apps built with the LlamaPress/Leonardo system. It contains only the user-owned parts of a Ruby on Rails project and an AI agent through LangGraph (Python). The Rails **framework skeleton** (Gemfile, bin, boot files, vendor, etc.) lives in the public `llamapress-simple` repo and is bundled into the Docker base image.

The design keeps this repo small, safe for AI-assisted editing, and still easy to "eject" into a normal Rails workflow by combining it with the skeleton.

See the starting rails project and base image here: https://github.com/kodykendall/llamapress-simple

---

## Quick Start for Devs:  
```
curl -fsSL "https://raw.githubusercontent.com/KodyKendall/Leonardo/refs/heads/main/bin/install/dev" -o install_leonardo_local.sh && bash install_leonardo_local.sh
```

## Quick Start Dev
```
clone your repo
bash bin/dev
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

## Ejection

If you want to run your Rails app without Docker:

1. Clone this overlay repo.
2. Clone the matching skeleton repo at the tag pinned in `docker-compose.yml` (`RAILS_IMAGE_REF`).
3. Copy overlay folders into skeleton:

   ```bash
   cp -R rails/app rails/db rails/config rails/test langgraph llamapress-simple/
   ```
4. Run:

   ```bash
   cd llamapress-simple-skeleton
   bundle install
   bin/rails s
   ```

The provided `scripts/eject.sh` automates this process.

---

## Deployment Philosophy

* **Local dev**: Run `docker compose -f docker-compose.yml -f docker-compose.dev.yml up`. Rails reloads overlay changes; agent reloads with `--reload`.
* **Production**: Run `docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d`. Rails overlay mounted RO; agent runs in hardened container. Deploy by bumping `IMAGE_REF` or pulling new overlay commits.

---

## Reproducibility

Your app is defined by the tuple:

**(Base skeleton/image digest + overlay Git commit)**

This ensures full reproducibility and clear separation of concerns.
