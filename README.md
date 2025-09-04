# Odoo Dev Environment (Docker, Odoo 18)

A reproducible, Docker-based Odoo development setup modeled after odoo.sh. It supports Enterprise, shared addons, test addons, and a developer branch, all orchestrated with Docker Compose and a single Makefile.

## What’s inside

- Dockerized services with healthchecks and restart policies.
- Host-cloned repositories (via SSH) mounted into the container for live development.
- Simple config via `.env` and `odoo.conf` (dev mode enabled: `dev = reload,all`).
- Makefile-driven workflows for repo management, DB restore, asset rebuild, and troubleshooting.
- Optional VS Code attach debugging via debugpy.

## Directory layout

- `docker-compose.yml` — Services and volumes (Odoo, Postgres).
- `Dockerfile` — Odoo image for dev; minimal utilities; debugpy included for attach debugging.
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
2. Add your data backup
    - Put your odoo.sh backup files in `./backup/`:
        - SQL dump at `./backup/dump.sql`
        - Filestore at `./backup/filestore/`
3. Start services
    - Optional: load filestore once
        - `make filestore`
    - Start the stack (non-destructive)
        - `make start`
    - Access Odoo at <http://localhost:8069>
    - Optional: quick smoke test
        - `make smoke` (expects HTTP 200 for /web/login and frontend assets)
    - Optional: debug
        - `make debug` to enable the debug adapter on port 5678 (non-blocking)
        - Or `make debug-wait` to wait for the debugger to attach before running
        - In VS Code, run “Attach to Odoo (debugpy)” from the Run and Debug panel
4. Restore DB (optional on first run)
    - If you want to restore from `./backup/dump.sql`:
        - `make reset-db`
        - This will: stop Odoo, terminate active DB sessions, drop/create the DB, restore the SQL dump, run a one-off Odoo upgrade (`-u all --stop-after-init`) via an overridden entrypoint, then restart Odoo.

## Make targets (summary)

- start — Non-destructive. Ensures repos exist/updated (reset-addons) and brings up containers.
- up — Compose up in background (builds if needed).
- reset-addons — Clone/update repos on host (enterprise, addons_main, addons_test, addons_my).
- reset-db — Drop/create DB, restore from `backup/dump.sql`, and run `-u all` once.
  - Internals: stops Odoo, terminates sessions, drops/creates DB, restores dump, runs a one-off upgrade with `/usr/bin/odoo ... --stop-after-init`, then restarts Odoo.
- filestore — Copy `backup/filestore` into `./filestore`.
- odoo-logs — Tail recent Odoo logs.
- update-apps-list — Refresh Apps registry (equivalent to UI “Update Apps List”).
- update-web-modules — Update web, website modules; quick asset refresh.
- rebuild-assets — Clear ir_attachment/ir_asset via SQL and rebuild web/website.
- smoke — Curl /web/login and frontend assets to assert HTTP 200; fails otherwise.
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
- Quick health check:
  - `make smoke`

## Developing modules

- Recommended extensions (install when prompted in the dev container):
  - Python, Pylance, Odoo IDE, Better Jinja, XML (Red Hat)
- Develop inside the container for correct Python environment:
  - From VS Code: Command Palette → “Dev Containers: Reopen in Container”
  - This attaches VS Code to the running `odoo` service and uses `/usr/bin/python3` in-container
- Create a new module skeleton under `addons_my`:
  - `make scaffold NAME=my_module`
  - Then update/install it: `docker compose exec odoo odoo -c /etc/odoo/odoo.conf -d $DB_NAME -u my_module --stop-after-init`
- Debug in VS Code:
  - `make debug-wait` to start with the adapter and wait
  - Run “Attach to Odoo (debugpy)” from VS Code
  - Set breakpoints in files under `addons_my`, `addons_test`, `addons_main`, or `enterprise`

## Troubleshooting

- Static files 500 errors: ensure `odoo.conf` doesn’t reference non-existent addon paths (no `/mnt/extra_addons`).
- CSS not applying:
  - `make update-web-modules` or `make rebuild-assets`, then hard-refresh
  - Check Network tab for `/web/assets/*` → expect HTTP 200
- Private repos fail to clone: ensure your SSH key is available to git (`ssh-agent` loaded) on the host.
- Restores: confirm `./backup/dump.sql` exists before running `make reset-db`.
- Debugging:
  - If attaching fails, ensure port 5678 is free and the container has DEBUG=1 (use `make debug`).
  - Set breakpoints in code under: core (`/opt/odoo`), enterprise (`/mnt/enterprise`), addons_main (`/mnt/addons_main`), addons_test (`/mnt/addons_test`), addons_my (`/mnt/addons_my`).

## Debugging

- Debug adapter is included via debugpy. Use `make debug` (non-blocking) or `make debug-wait` (waits for attach) and the “Attach to Odoo (debugpy)” configuration in VS Code.

## License

Internal development only. Odoo Enterprise and custom modules retain their respective licenses.
