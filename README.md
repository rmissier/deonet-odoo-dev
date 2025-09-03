# Odoo Dev Environment (Docker, Odoo 18)

A reproducible, Docker-based Odoo development setup modeled after odoo.sh. It supports Enterprise, shared addons, test addons, and a developer branch, all orchestrated with Docker Compose and a single Makefile.

## What’s inside

- Dockerized services with healthchecks and restart policies.
- Host-cloned repositories (via SSH) mounted into the container for live development.
- Simple config via `.env` and `odoo.conf` (dev mode enabled: `dev = reload,all`).
- Makefile-driven workflows for repo management, DB restore, asset rebuild, and troubleshooting.

## Directory layout

- `docker-compose.yml` — Services and volumes (Odoo, Postgres).
- `Dockerfile` — Odoo image for dev; minimal utilities; no debugpy.
- `entrypoint.sh` — Runs Odoo with `-c /etc/odoo/odoo.conf`.
- `odoo.conf` — Odoo configuration; addons_path mapped to `/mnt/...` and core addons.
- `enterprise/` — Odoo Enterprise addons (host-cloned; RO mount by default).
- `addons_main/` — Shared addons (host-cloned; RO mount by default).
- `addons_test/` — Test addons (host-cloned; RW mount).
- `addons_my/` — Your personal dev branch (host-cloned; RW mount).
- `backup/` — Place `dump.sql` and `filestore/` here (from odoo.sh backup).
- `filestore/` — Live filestore mounted to the container.
- `.env` — Local env vars (DB, branches). See `.env.example`.

## Prerequisites

- Docker and Docker Compose
- Git on host with SSH access to private repos (enterprise/addons)
- Recommended: VS Code + Docker/Containers, PostgreSQL extensions

## How to use (quick start)

1. Clone this repo and prepare env

   - Copy `.env.example` to `.env` and adjust as needed:
      - `DB_NAME`, `DB_USER`, `DB_PASSWORD`
      - `ADDONS_MY_BRANCH` (defaults to `main` if unset)

1. Add your data backup

   - Put your odoo.sh backup files in `./backup/`:
      - SQL dump at `./backup/dump.sql`
      - Filestore at `./backup/filestore/`

1. Start services

   - Optional: load filestore once
      - `make filestore`
   - Start the stack (non-destructive)
      - `make start`
   - Access Odoo at <http://localhost:8069>

1. Restore DB (optional on first run)

   - If you want to restore from `./backup/dump.sql`:
      - `make reset-db`

## Make targets (summary)

- start — Non-destructive. Ensures repos exist/updated (reset-addons) and brings up containers.
- up — Compose up in background (builds if needed).
- reset-addons — Clone/update repos on host (enterprise, addons_main, addons_test, addons_my).
- reset-db — Drop/create DB, restore from `backup/dump.sql`, and run `-u all` once.
- filestore — Copy `backup/filestore` into `./filestore`.
- odoo-logs — Tail recent Odoo logs.
- update-apps-list — Refresh Apps registry (equivalent to UI “Update Apps List”).
- update-web-modules — Update web, website modules; quick asset refresh.
- rebuild-assets — Clear ir_attachment/ir_asset via SQL and rebuild web/website.
- db-shell — psql shell in the db container.
- odoo-shell — Odoo shell in the app container.
- url — Print the local URL.
- nuke — Stop containers and delete repos + db + filestore (DESTRUCTIVE).
- tidy — Remove stray `.DS_Store` files.

## Configuration notes

- `.env` controls DB credentials and branches. It’s ignored by git and Docker build context. Share `.env.example` for onboarding.
- `odoo.conf` enables dev mode and logs to stdout. Addons are looked up in:
   - `/mnt/enterprise`, `/mnt/addons_main`, `/mnt/addons_test/addons`, `/mnt/addons_test/deonet_addons`, `/mnt/addons_my`, plus core addons.
- We removed `/mnt/extra_addons` to avoid 500 errors on static files when the path doesn’t exist.
- Ports: Odoo on 8069, Postgres on 5432 (both exposed on localhost).

## Common workflows

- Update code from remotes: `make reset-addons`
- Rebuild website assets if pages look unstyled:
   - `make rebuild-assets`, then hard-refresh (Cmd/Ctrl+Shift+R)
- Update the Apps registry: `make update-apps-list`
- Logs and shells:
   - `make odoo-logs`, `make db-shell`, `make odoo-shell`

## Troubleshooting

- Static files 500 errors: ensure `odoo.conf` doesn’t reference non-existent addon paths (no `/mnt/extra_addons`).
- CSS not applying:
   - `make update-web-modules` or `make rebuild-assets`, then hard-refresh
   - Check Network tab for `/web/assets/*` → expect HTTP 200
- Private repos fail to clone: ensure your SSH key is available to git (`ssh-agent` loaded) on the host.
- Restores: confirm `./backup/dump.sql` exists before running `make reset-db`.

## Debugging

- The image does not include debugpy. Prefer `odoo shell`, logging, or add debugpy temporarily in a feature branch if required.

## License

Internal development only. Odoo Enterprise and custom modules retain their respective licenses.
