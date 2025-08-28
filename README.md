# Odoo Development Environment (Odoo.sh-like)

This project provides a Docker-based Odoo development environment that closely mimics the workflow and structure of odoo.sh. It is designed for teams to collaborate efficiently, with support for Odoo Community, Enterprise, and custom addons. All code and environment management is handled via a single Makefile for easy onboarding and updates.

## Features

- **Consistent local environment** for all developers using Docker and docker-compose
- **Support for private repositories** (Odoo Enterprise, custom addons) via SSH agent forwarding
- **Branch and path management** via a centralized `.env` file
- **Persistent data and filestore** for live development
- **Easy configuration** for database, Odoo, and addons
- **All code and repo management via Makefile** (no separate scripts)

## Folder Structure

- `docker-compose.yml` — Main orchestration file for services
- `odoo.conf` — Odoo configuration (used directly, not in config/)
- `addons-main/`, `addons-test/`, `addons-my/`, `odoo-enterprise/` — Custom and enterprise addons
- `filestore/` — Persistent Odoo filestore
- `backup/` — Directory to store the backup from odoo.sh
- `.env` — Centralized environment variables

### Prerequisites

- Docker
- Docker Compose
- SSH key with access to private repositories (added to your ssh-agent)
- Visual studio code with extensions: Container Tools, PostgreSQL, Python

### Setup

1. **Clone this repository**
2. **Edit `.env`** as needed for your branches, paths, and credentials

   - You must update ADDONS_MY_BRANCH, set it to your name
3. **Download and place the database and filestore backup from Odoo.sh:**

   - Go to your Odoo.sh project in the web interface.
   - Navigate to the **Backups** section.
   - Download the latest backup (usually a `.zip` file) and unpack it.
   - Place the database dump (e.g., `dump.sql`) at the path specified by `DB_DUMP_FILE` in your `.env` (e.g., `./backup/dump.sql`).
   - Place the filestore directory at the path specified by `ODOO_BACKUP_PATH` in your `.env` (e.g., `./backup/filestore`).

4. **Start the environment and manage code/database:**

   The Makefile automates all common tasks:

   ```sh
   make start
   ```

   This will:
   - Clone or update all required addons repositories and branches (using git, as defined in `.env`)
   - Start the Docker containers
   - Restore the database from a dump if the database is empty

   To manually restore the database at any time:

   ```sh
   make reset-db
   ```

   To reset code to remote repositories:

   ```sh
   make reset-addons
   ```

## Makefile targets

Common commands you’ll use during development:

- make start — Clone/update repos (reset-addons), start containers, restore DB if empty.
- make reset-addons — Clone repositories if missing, or hard reset each repo to its remote branch as defined in `.env`.
- make reset-db — Drop, create, and restore the database from `DB_DUMP_FILE`.
- make filestore — Copy the filestore from `ODOO_BACKUP_PATH/filestore` into `./filestore` (mounted into the container at `/var/lib/odoo`).
- make up — Start containers in the background.
- make odoo-logs — Tail recent Odoo logs to troubleshoot.
- make update-apps-list — Refresh the Apps registry (same as “Update Apps List” in UI).
- make install-deonet-addons — Install the Deonet test modules (optional helper).
- make update-web-modules — Update `web` and `website` modules to rebuild website assets.

### Access

- Odoo: <http://localhost:8069>
- PostgreSQL: Use a VS Code extension (e.g., Microsoft PostgreSQL or SQLTools) to connect to `localhost:5432` with the credentials from your `.env` file.

## Database & Filestore: Getting a Backup from Odoo.sh

Odoo.sh does not provide SSH access. To get a database and filestore backup:

- Go to your Odoo.sh project in the web interface.
- Navigate to the **Backups** section.
- Download the latest backup (usually a `.zip` file) and unpack it.
- Place the database dump (e.g., `dump.sql`) at the path specified by `DB_DUMP_FILE` in your `.env` (e.g., `./backup/dump.sql`).
- Place the filestore directory at the path specified by `ODOO_BACKUP_PATH` in your `.env` (e.g., `./backup/filestore`).
- Run `make reset-db` to restore the database in your local environment.
- Run `make filestore` to restore the filestore in your local environment.

The Makefile will automatically restore the database from this dump if the local database is empty when you run `make start`.

### Notes

- SSH agent forwarding is enabled for secure access to private git repositories during build.
- All configuration (database, Odoo, branches, paths) is managed via `.env`.
- Addons and data are mounted as volumes for live development and persistence.
- The Makefile automates all code updates, repository management, container startup, and database/filestore restoration.

## Customization

- Add or change addon folders as needed (update `.env`, `docker-compose.yml`, and `odoo.conf` accordingly)
- Adjust Odoo configuration in `odoo.conf`
- Use different branches for testing or feature development

## Troubleshooting

- Ensure your SSH agent is running and has the correct keys loaded for private repo access.
- If you change `.env`, rebuild the containers to apply changes.

## License

This project is for internal development use. Odoo Enterprise and custom modules are subject to their respective licenses.
