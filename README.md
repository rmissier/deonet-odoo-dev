# Odoo Development Environment (Odoo.sh-like)

This project provides a Docker-based Odoo development environment that closely mimics the workflow and structure of odoo.sh. It is designed for teams to collaborate efficiently, with support for Odoo Community, Enterprise, and custom addons.

## Features

- **Consistent local environment** for all developers using Docker and docker-compose
- **Support for private repositories** (Odoo Enterprise, custom addons) via SSH agent forwarding
- **Branch and path management** via a centralized `.env` file
- **Persistent data and filestore** for live development
- **Easy configuration** for database, Odoo, and addons
- **Optional tools** like pgAdmin for database management

## Folder Structure

- `docker-compose.yml` — Main orchestration file for services
- `config/odoo.conf` — Odoo configuration (can be overridden)
- `addons-*/`, `odoo-enterprise/` — Custom and enterprise addons
- `filestore/` — Persistent Odoo filestore
- `.env` — Centralized environment variables





### Prerequisites

- Docker
- Docker Compose
- SSH key with access to private repositories (added to your ssh-agent)

### Setup

1. **Clone this repository**
2. **Clone all required addons repositories and branches:**

   ```sh
   bash clone_addons.sh
   ```

   This script reads repository URLs and branch names from your `.env` file and clones them into the correct folders. Make sure your SSH agent is running and has access to the private repositories before running the script.

3. **Copy and edit `.env`** as needed for your branches, paths, and credentials
4. **Download and place the database backup from Odoo.sh:**

   - Go to your Odoo.sh project in the web interface.
   - Navigate to the **Backups** section.
   - Download the latest backup (usually a `.dump` file).
   - Place the downloaded file at the path specified by `DB_DUMP_FILE` in your `.env` (e.g., `./db-dumps/sanitized.dump`).

5. **Start the environment and manage code/database:**

   The Makefile automates most common tasks:

   ```sh
   make start
   ```

   This will:
   - Pull the latest code for all addons (using git)
   - Check out the correct branches as defined in `.env`
   - Start the Docker containers
   - Restore the database from a dump if the database is empty

   To manually restore the database at any time:

   ```sh
   make reset-db
   ```

   To update your code from remote repositories:

   ```sh
   make pull-code
   ```

### Access

- Odoo: <http://localhost:8069>
- pgAdmin: <http://localhost:8080> (default: <admin@example.com> / admin)

## Database: Getting a Backup from Odoo.sh

Odoo.sh does not provide SSH access. To get a database backup:

1. Go to your Odoo.sh project in the web interface.
2. Navigate to the **Backups** section.
3. Download the latest backup (usually a `.dump` file).
4. Place the downloaded file at the path specified by `DB_DUMP_FILE` in your `.env` (e.g., `./db-dumps/sanitized.dump`).
5. Run `make reset-db` to restore the database in your local environment.

The Makefile will automatically restore the database from this dump if the local database is empty when you run `make start`.

### Notes

- SSH agent forwarding is enabled for secure access to private git repositories during build.
- All configuration (database, Odoo, branches, paths) is managed via `.env`.
- Addons and data are mounted as volumes for live development and persistence.
- The Makefile automates code updates, branch management, container startup, and database restoration.

## Customization

- Add or change addon folders as needed (update `.env` and `docker-compose.yml` accordingly)
- Adjust Odoo configuration in `config/odoo.conf`
- Use different branches for testing or feature development

## Troubleshooting

- Ensure your SSH agent is running and has the correct keys loaded for private repo access.
- If you change `.env`, rebuild the containers to apply changes.

## License

This project is for internal development use. Odoo Enterprise and custom modules are subject to their respective licenses.

