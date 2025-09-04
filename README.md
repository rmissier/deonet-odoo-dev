# Odoo Dev Environment (Docker, Odoo 18)

A reproducible, Docker-based Odoo development setup mode## Developing modules

- Recommended extensio## Troubleshooting

## Common Issues

### **Static files 500 errors**

- Ensure `odoo.conf` doesn't reference non-existent addon paths (no `/mnt/extra_addons`)
- Check that all mounted addon directories exist on the host

### **CSS not applying / Website looks unstyled**

- Run `make rebuild-assets`, then hard-refresh browser (Cmd/Ctrl+Shift+R)
- Alternative: `make update-web-modules` for a lighter refresh
- Check Network tab for `/web/assets/*` → expect HTTP 200 responses
- Verify no JavaScript console errors in browser dev tools

### **Private repos fail to clone**

- Ensure your SSH key is available to git (`ssh-agent` loaded) on the host
- Test SSH access: `ssh -T git@github.com`
- Check that your SSH key has access to the private repositories

### **Database restore issues**

- Confirm `./backup/dump.sql` exists before running `make reset-db`
- Check that dump file is valid SQL: `head -20 ./backup/dump.sql`
- Ensure PostgreSQL version compatibility (container uses PostgreSQL 16)

### **Container startup failures**

- Check container logs: `docker compose logs odoo` or `docker compose logs db`
- Verify `.env` file exists and contains required variables
- Ensure ports 8069, 5432, and 5678 are not in use by other services

### Debugging Issues

#### **VS Code debugger won't attach**

- Ensure port 5678 is free and the container has DEBUG=1 (use `make debug`)
- Check that debugpy is listening: `docker compose logs odoo | grep debugpy`
- Verify VS Code debugger extension is installed and configured
- Try `make debug-wait` if the process starts too quickly

#### **Breakpoints not hitting**

- Set breakpoints in code under the correct paths:
  - Core: `/opt/odoo`
  - Enterprise: `/mnt/enterprise`
  - Addons main: `/mnt/addons_main`
  - Test addons: `/mnt/addons_test`
  - Personal: `/mnt/addons_my`
- Ensure the module containing your breakpoint is actually loaded/installed
- Check that file paths match between local and container (see path mappings in `.vscode/launch.json`)

### Performance Issues

#### **Slow container startup**

- Monitor resource usage: `docker stats`
- Consider adding resource limits in `docker-compose.yml`
- Check available disk space for Docker volumes

#### **Odoo slow to respond**

- Enable Odoo performance logging by setting `log_level = debug` in `odoo.conf`
- Check for long-running queries: `make db-shell` then `SELECT * FROM pg_stat_activity;`
- Consider adjusting worker configuration in `odoo.conf`

### Development Workflow Issues

#### **Module not appearing in Apps**

- Run `make update-apps-list` to refresh the module registry
- Check module manifest (`__manifest__.py`) for syntax errors
- Verify module is in a directory that's mounted and in `addons_path`

#### **Changes not reflected**

- Check that dev mode is enabled: `dev = reload,all` in `odoo.conf`
- For model changes, restart Odoo: `docker compose restart odoo`
- For view changes, try updating the module: `docker compose exec odoo odoo -c /etc/odoo/odoo.conf -d $DB_NAME -u module_name --stop-after-init`

#### **Permission issues with files/folders**

- Check file ownership: `ls -la` in the affected directory
- Ensure the `odoo` user (UID 101) can read/write the mounted volumes
- On host: `sudo chown -R 101:101 ./addons_my` if needed

### Emergency Recovery

#### **Complete environment reset**

- Nuclear option: `make nuke` (removes all data - use with caution!)
- Rebuild from scratch: `make reset-addons && make up`
- Restore from backup: `make filestore && make reset-db`

#### **Container won't start after changes**

- Remove container and rebuild: `docker compose down && docker compose up -d --build`
- Check for syntax errors in modified files
- Reset to working state: `git checkout -- .` then rebuild when prompted in the dev container):
  - Python, Pylance, Odoo IDE, Better Jinja, XML (Red Hat)
- Develop inside the container for correct Python environment:
  - From VS Code: Command Palette → "Dev Containers: Reopen in Container"
  - This attaches VS Code to the running `odoo` service and uses `/usr/bin/python3` in-container
- Create a new module skeleton under `addons_my`:
  - `make scaffold NAME=my_module`
  - Then update/install it: `docker compose exec odoo odoo -c /etc/odoo/odoo.conf -d $DB_NAME -u my_module --stop-after-init`
- Debug in VS Code:
  - `make debug-wait` to start with the adapter and wait
  - Run "Attach to Odoo (debugpy)" from VS Code
  - Set breakpoints in files under `addons_my`, `addons_test`, `addons_main`, or `enterprise`

## Installing Python packages

The `odoo` user has passwordless sudo access for development convenience:

```bash
# Inside the container (via docker compose exec odoo bash or dev container)
sudo apt update
sudo apt install python3-requests python3-pandas
sudo pip3 install some-development-package

# Alternative: use the odoo-shell for quick package installs
docker compose exec odoo bash
sudo apt install python3-beautifulsoup4
```

Note: System-wide packages persist only while the container is running. For permanent dependencies, add them to the Dockerfile.

## Git operations inside container

SSH keys are automatically mounted from your host `~/.ssh` directory, allowing git operations inside the container:

```bash
# Inside the container (via docker compose exec odoo bash or dev container)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Now you can use git normally
cd /mnt/addons_my
git add .
git commit -m "Your commit message"
git push origin your-branch
```

**Prerequisites:**
- Ensure your SSH agent is running on the host: `ssh-add -l`
- Your SSH keys should be in `~/.ssh/` with proper permissions (600 for private keys)
- Test SSH access from host first: `ssh -T git@github.com`

**Note:** The SSH agent socket is forwarded to the container, so you don't need to enter SSH key passphrases inside the container..sh. It supports Enterprise, shared addons, test addons, and a developer branch, all orchestrated with Docker Compose and a single Makefile.

## What’s inside

- Dockerized services with healthchecks and restart policies.
- Host-cloned repositories (via SSH) mounted into the container for live development.
- Simple config via `.env` and `odoo.conf` (dev mode enabled: `dev = reload,all`).
- Makefile-driven workflows for repo management, DB restore, asset rebuild, and troubleshooting.
- Optional VS Code attach debugging via debugpy.
- Development-friendly container with sudo access for installing system packages.

## Directory layout

- `docker-compose.yml` — Services and volumes (Odoo, Postgres).
- `Dockerfile` — Odoo image for dev; minimal utilities; debugpy and sudo included for development; odoo user has passwordless sudo access.
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
