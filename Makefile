
.PHONY: filestore url start up reset-addons reset-db wait-for-db odoo-logs update-apps-list update-web-modules db-shell odoo-shell nuke rebuild-assets tidy

wait-for-db:
	@echo "⌛ Waiting for database to be ready..."
	@until docker compose exec -T db pg_isready -U $(DB_USER); do \
		sleep 1; \
	done

# Load DB credentials and developer branch from .env if present
-include .env
ifdef DB_NAME
export DB_NAME
endif
ifdef DB_USER
export DB_USER
endif
ifdef DB_PASSWORD
export DB_PASSWORD
endif
ifdef ADDONS_MY_BRANCH
export ADDONS_MY_BRANCH
endif
ifndef ADDONS_MY_BRANCH
ADDONS_MY_BRANCH := main
export ADDONS_MY_BRANCH
endif


.DEFAULT_GOAL := start


# Non-destructive start: update repos, bring up services; DB reset is manual
start: reset-addons up


# Remove developer workspace folders and DB/filestore (dangerous - irreversible)
nuke:
	@echo "\033[33mStopping and removing compose containers...\033[0m"
	-@docker compose down || true
	@echo "\u001b[33mRemoving folders: ./enterprise ./addons_main ./addons_my ./addons_test ./db ./filestore\u001b[0m"
	-@rm -rf ./enterprise ./addons_main ./addons_my ./addons_test ./db ./filestore
	@echo "\u001b[32mWorkspace cleaned.\u001b[0m"

# Housekeeping: remove stray OS files
tidy:
	@find . -name '.DS_Store' -type f -delete -print || true
	@echo "Tidied up stray system files."


# Clone or update all Odoo addon repositories
reset-addons:
	@echo "📁 Creating required directories..."
	mkdir -p ./db ./backup

	@echo "🔄 Ensuring enterprise repo for baking into image..."
	@if [ -d "./enterprise/.git" ]; then \
		echo "Updating enterprise in ./enterprise..."; \
		pushd ./enterprise > /dev/null; \
		git fetch origin 18.0; \
		git reset --hard origin/18.0; \
		popd > /dev/null; \
	else \
		echo "Cloning enterprise..."; \
		git clone -b 18.0 git@github.com:itdeonet/odoo-enterprise.git ./enterprise; \
		rm -rf ./enterprise/.git; \
	fi

	@echo "🔄 Ensuring addons_main repo for baking into image..."
	@if [ -d "./addons_main/.git" ]; then \
		echo "Updating addons_main in ./addons_main..."; \
		pushd ./addons_main > /dev/null; \
		git fetch origin main; \
		git reset --hard origin/main; \
		popd > /dev/null; \
	else \
		echo "Cloning addons_main..."; \
		git clone -b main git@github.com:itdeonet/odoo.git ./addons_main; \
		rm -rf ./addons_main/.git; \
	fi

	@echo "🔄 Ensuring test addons repo..."
	@if [ -d "./addons_test/.git" ]; then \
		echo "Updating test addons in ./addons_test..."; \
		pushd ./addons_test > /dev/null; \
		git fetch origin Test; \
		git reset --hard origin/Test; \
		popd > /dev/null; \
	else \
		echo "Cloning test addons..."; \
		git clone -b Test git@github.com:itdeonet/odoo.git ./addons_test; \
	fi

	@echo "🔄 Ensuring my feature branch repo..."
	@if [ -d "./addons_my/.git" ]; then \
		echo "Updating my feature branch in ./addons_my..."; \
		pushd ./addons_my > /dev/null; \
		git fetch origin $(ADDONS_MY_BRANCH); \
		git reset --hard origin/$(ADDONS_MY_BRANCH); \
		popd > /dev/null; \
	else \
		echo "Cloning my feature branch..."; \
		git clone -b $(ADDONS_MY_BRANCH) git@github.com:itdeonet/odoo.git ./addons_my; \
	fi

	@echo "✅ All repositories cloned or updated successfully."


up:
	docker compose up -d --build


reset-db: wait-for-db
	@if [ ! -f "./backup/dump.sql" ]; then \
		echo "❌ Database dump file ./backup/dump.sql not found!"; \
		exit 1; \
	fi
	docker compose exec -T db dropdb -U $(DB_USER) $(DB_NAME) || true
	docker compose exec -T db createdb -U $(DB_USER) $(DB_NAME)
	cat ./backup/dump.sql | docker compose exec -T db psql -U $(DB_USER) -d $(DB_NAME)
	docker compose exec odoo odoo -c /etc/odoo/odoo.conf -u all -d $(DB_NAME) --stop-after-init


filestore:
	@echo "🔀 Copy filestore"
	cp -r "./backup/filestore" ./


odoo-logs:
	docker compose logs --no-color --tail=200 odoo


# Refresh the list of available modules (like clicking "Update Apps List")
update-apps-list: wait-for-db
	# Use Odoo shell reading from stdin
	@docker compose exec -T odoo odoo shell -d $(DB_NAME) <<-'PY'
	env['ir.module.module'].update_list()
	print('Apps list updated')
	PY

# Rebuild/update core web modules to refresh assets if the website looks broken
update-web-modules: wait-for-db
	# Update web and website modules; ignore if not installed
	docker compose exec odoo odoo -c /etc/odoo/odoo.conf -d $(DB_NAME) -u web,website --stop-after-init || true


# Print the local Odoo URL for quick access
url:
	@echo "Odoo is available at: http://localhost:8069"

db-shell: wait-for-db
	docker compose exec -it db psql -U $(DB_USER) -d $(DB_NAME)

odoo-shell: wait-for-db
	docker compose exec -it odoo odoo shell -d $(DB_NAME)

# Clear and rebuild asset bundles (CSS/JS) if the website looks unstyled
rebuild-assets: wait-for-db
	@echo "🧹 Clearing asset bundles (SQL: ir_attachment + ir_asset) ..."
	@docker compose exec -T db psql -U $(DB_USER) -d $(DB_NAME) -v ON_ERROR_STOP=1 -c "DELETE FROM ir_attachment WHERE name ILIKE 'web.assets_%' OR name ILIKE 'website.assets_%';" || true
	@docker compose exec -T db psql -U $(DB_USER) -d $(DB_NAME) -v ON_ERROR_STOP=1 -c "DELETE FROM ir_asset;" || true
	@echo "🔧 Rebuilding web and website modules (this may take a moment)..."
	@docker compose exec odoo odoo -c /etc/odoo/odoo.conf -d $(DB_NAME) -u web,website --stop-after-init || true
	@echo "✅ Asset rebuild complete. Hard-refresh your browser (Ctrl/Cmd+Shift+R)."
