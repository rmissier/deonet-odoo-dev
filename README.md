# Odoo Dev Environment (Docker, Odoo 18)

A reproducible, Docker-based Odoo development setup with debugging support, SSH integration, and smart automation.

## Features

- **Docker Compose**: Multi-service setup (Odoo 18 + PostgreSQL 16)
- **Development-friendly**: Passwordless sudo, SSH key mounting, debugging support
- **Smart automation**: One-command setup with intelligent database handling
- **Addon management**: Structured repositories for enterprise, main, test, and custom addons
- **VS Code integration**: Dev container with extensions and debugger configuration

## Make targets (summary)

- start — Smart setup. Updates repos, brings up containers, installs dependencies. Automatically restores database if not initialized. Always ends with smoke test.
- up — Compose up in background (builds if needed).
- reset-addons — Clone/update repos on host (enterprise, addons_main, addons_test, addons_my).
- reset-db — Drop/create DB, restore from `backup/dump.sql`, and run `-u all` once.
- filestore — Copy `backup/filestore` into `./filestore`.
- install-deps — Run /mnt/addons_my/install_dependencies.sh script in the container.
- odoo-logs — Tail recent Odoo logs.
- update-apps-list — Refresh Apps registry (equivalent to UI "Update Apps List").
- rebuild-assets — Clear ir_attachment/ir_asset via SQL and rebuild web/website.
- smoke — Curl /web/login and frontend assets to assert HTTP 200; fails otherwise.

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

3. **One-command setup**: `make start`
   - Updates repositories, builds containers, installs dependencies
   - **Smart database handling**: Automatically checks if database is initialized
     - **First time or empty DB**: Restores from `./backup/dump.sql`
     - **Existing data**: Preserves your current database
   - **Always ends with**: Smoke test to verify everything works
   - Access Odoo at <http://localhost:8069>

**That's it!** The smart start handles everything automatically - no manual database setup needed.

### Optional: Development features

- **Filestore**: `make filestore` (one-time copy from backup)
- **Debug mode**:
  - `make debug` to enable debugger on port 5678 (non-blocking)
  - `make debug-wait` to wait for debugger before starting
  - In VS Code: "Attach to Odoo (debugpy)" from Run and Debug panel
- **Manual smoke test**: `make smoke` (checks login and assets)

1. Advanced: Manual database operations (usually not needed)
   - Force restore from backup: `make reset-db`
     - This will: stop Odoo, terminate active DB sessions, drop/create the DB, restore the SQL dump, run a one-off Odoo upgrade (`-u all --stop-after-init`), then restart Odoo

## Troubleshooting

### **Static files/CSS not applying / Website looks unstyled**

- Run `make rebuild-assets`, then hard-refresh browser (Cmd/Ctrl+Shift+R)
- Check Network tab for `/web/assets/*` → expect HTTP 200 responses
- Verify no JavaScript console errors in browser dev tools
- Ensure `odoo.conf` doesn't reference non-existent addon paths (no `/mnt/extra_addons`)
- Check that all mounted addon directories exist on the host

### **Private repos fail to clone**

- Ensure your SSH key is available to git (`ssh-agent` loaded) on the host
- Test SSH access: `ssh -T git@github.com`
- Check that your SSH key has access to the private repositories

### **Database restore issues**

- Confirm `./backup/dump.sql` exists before running `make reset-db`
- Check that dump file is valid SQL: `head -20 ./backup/dump.sql`
- Ensure PostgreSQL version compatibility (container uses PostgreSQL 16)

### **Container startup failures**

- Check Docker logs: `docker compose logs`
- Verify all required directories exist: `./backup/`, addon directories
- Ensure no port conflicts (8069, 5432, 5678)

### **Permission issues**

- Check file ownership in mounted directories
- Ensure SSH keys have correct permissions (600 for private keys)

## Developing modules

### Creating new modules

Use the scaffold target to create a new module structure:

```bash
make scaffold NAME=my_new_module
```

This creates a basic module structure in `./addons_my/my_new_module/` with:

- `__manifest__.py` with basic metadata
- `models/` directory with sample model
- `security/` directory with access rights
- `views/` directory with sample view

### Installing Python packages

The container includes sudo access for the `odoo` user. You can install Python packages system-wide:

```bash
# Enter the container
docker compose exec odoo bash

# Install packages with sudo
sudo pip install package-name
# or
sudo apt update && sudo apt install package-name
```

### SSH operations

SSH keys are mounted into the container for git operations:

```bash
# Inside the container, you can use git normally
git commit -m "My changes"
git push origin feature-branch
```

Setup requirements:

- Ensure your SSH agent is running on the host: `ssh-add -l`
- Your SSH keys should be in `~/.ssh/` on the host
- Test SSH access: `ssh -T git@github.com`

## Docker Architecture

### Services

- **odoo**: Main Odoo application (port 8069, debug port 5678)
- **db**: PostgreSQL 16 database (port 5432)

### Volumes

- `./enterprise` → `/mnt/enterprise` (read-only)
- `./addons_main` → `/mnt/addons_main` (read-only)
- `./addons_test` → `/mnt/addons_test` (read-write)
- `./addons_my` → `/mnt/addons_my` (read-write)
- `./filestore` → `/var/lib/odoo/filestore`
- `./db` → PostgreSQL data directory
- `~/.ssh` → `/var/lib/odoo/.ssh` (SSH keys for git)

### Environment Variables

Configure via `.env` file:

- `DB_NAME` - Database name
- `DB_USER` - Database user
- `DB_PASSWORD` - Database password
- `ADDONS_MY_BRANCH` - Branch for your custom addons repo

## Advanced Usage

### Debug Mode

Enable Python debugger (debugpy) on port 5678:

```bash
# Start with debug enabled
make debug

# Or start and wait for debugger to attach
make debug-wait

# Turn off debug mode
make debug-off
```

In VS Code, use the "Attach to Odoo (debugpy)" configuration from `.vscode/launch.json`.

### Database Operations

```bash
# Reset database from backup
make reset-db

# Access database shell
make db-shell

# Access Odoo shell
make odoo-shell

# Update apps list
make update-apps-list
```

### Asset Management

```bash
# Rebuild CSS/JS assets
make rebuild-assets

# View Odoo logs
make odoo-logs
```

### Complete Reset

⚠️ **Dangerous**: Removes all data and repositories

```bash
make nuke
```

This removes: `./enterprise`, `./addons_main`, `./addons_my`, `./addons_test`, `./db`, `./filestore`

## VS Code Integration

The repository includes a `.devcontainer/` configuration for VS Code development containers with:

- Python and PostgreSQL extensions
- GitHub Copilot integration
- Debugger configuration for Odoo
- Proper container user mapping

Open the project in VS Code and select "Reopen in Container" when prompted.
