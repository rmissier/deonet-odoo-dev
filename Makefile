
.PHONY: filestore sync-addons

wait-for-db:
	@echo "⏳ Waiting for database to be ready..."
	@until docker compose exec -T db pg_isready -U $(POSTGRES_USER) -d $(ODOO_DB_NAME); do \
		sleep 1; \
	done

# Load variables from .env
include .env
export $(shell sed 's/=.*//' .env)

.DEFAULT_GOAL := start


start: reset-addons up maybe-restore-db install-deonet-addons


# Clone or update all Odoo addon repositories
reset-addons:
	@echo "📁 Creating required directories..."
	mkdir -p $(ODOO_DB_PATH) $(ODOO_BACKUP_PATH)

	@echo "🔄 Ensuring Odoo Enterprise repo..."
	@if [ -d "$(ODOO_ENTERPRISE_PATH)/.git" ]; then \
		echo "Updating Odoo Enterprise in $(ODOO_ENTERPRISE_PATH)..."; \
		pushd $(ODOO_ENTERPRISE_PATH) > /dev/null; \
		git fetch origin $(ENTERPRISE_BRANCH); \
		git reset --hard origin/$(ENTERPRISE_BRANCH); \
		popd > /dev/null; \
	else \
		echo "Cloning Odoo Enterprise..."; \
		git clone -b $(ENTERPRISE_BRANCH) $(GIT_ENTERPRISE_REPO) $(ODOO_ENTERPRISE_PATH); \
	fi

	@echo "🔄 Ensuring main addons repo..."
	@if [ -d "$(ADDONS_MAIN_PATH)/.git" ]; then \
		echo "Updating main addons in $(ADDONS_MAIN_PATH)..."; \
		pushd $(ADDONS_MAIN_PATH) > /dev/null; \
		git fetch origin $(ADDONS_MAIN_BRANCH); \
		git reset --hard origin/$(ADDONS_MAIN_BRANCH); \
		popd > /dev/null; \
	else \
		echo "Cloning main addons..."; \
		git clone -b $(ADDONS_MAIN_BRANCH) $(GIT_CUSTOM_REPO) $(ADDONS_MAIN_PATH); \
	fi

	@echo "🔄 Ensuring test addons repo..."
	@if [ -d "$(ADDONS_TEST_PATH)/.git" ]; then \
		echo "Updating test addons in $(ADDONS_TEST_PATH)..."; \
		pushd $(ADDONS_TEST_PATH) > /dev/null; \
		git fetch origin $(ADDONS_TEST_BRANCH); \
		git reset --hard origin/$(ADDONS_TEST_BRANCH); \
		popd > /dev/null; \
	else \
		echo "Cloning test addons..."; \
		git clone -b $(ADDONS_TEST_BRANCH) $(GIT_CUSTOM_REPO) $(ADDONS_TEST_PATH); \
	fi

	@echo "🔄 Ensuring my feature branch repo..."
	@if [ -d "$(ADDONS_MY_PATH)/.git" ]; then \
		echo "Updating my feature branch in $(ADDONS_MY_PATH)..."; \
		pushd $(ADDONS_MY_PATH) > /dev/null; \
		git fetch origin $(ADDONS_MY_BRANCH); \
		git reset --hard origin/$(ADDONS_MY_BRANCH); \
		popd > /dev/null; \
	else \
		echo "Cloning my feature branch..."; \
		git clone -b $(ADDONS_MY_BRANCH) $(GIT_CUSTOM_REPO) $(ADDONS_MY_PATH); \
	fi

	@echo "✅ All repositories cloned or updated successfully."

filestore:
	@echo "🔀 Copy filestore"
	cp -r "${ODOO_BACKUP_PATH}/filestore" ./

up:
	docker compose up -d --build

odoo-logs:
	docker compose logs --no-color --tail=200 odoo

# Refresh the list of available modules (like clicking "Update Apps List")
update-apps-list: wait-for-db
	# Uses odoo shell to update module registry
	docker compose exec odoo odoo shell -d $(ODOO_DB_NAME) -c "env['ir.module.module'].update_list()"

maybe-restore-db: wait-for-db
	@if ! docker compose exec -T db psql -U $(POSTGRES_USER) -d $(ODOO_DB_NAME) -c '\dt' | grep -q .; then \
		echo "📦 Database is empty — restoring from dump..."; \
		$(MAKE) reset-db; \
	else \
		echo "✅ Database already has data — skipping restore."; \
	fi

reset-db: wait-for-db
	@if [ ! -f "$(DB_DUMP_FILE)" ]; then \
		echo "❌ Database dump file $(DB_DUMP_FILE) not found!"; \
		exit 1; \
	fi
	docker compose exec -T db dropdb -U $(POSTGRES_USER) $(ODOO_DB_NAME) || true
	docker compose exec -T db createdb -U $(POSTGRES_USER) $(ODOO_DB_NAME)
	cat $(DB_DUMP_FILE) | docker compose exec -T db psql -U $(POSTGRES_USER) -d $(ODOO_DB_NAME)
	docker compose exec odoo odoo -u all -d $(ODOO_DB_NAME) --stop-after-init

# Rebuild/update core web modules to refresh assets if the website looks broken
update-web-modules: wait-for-db
	# Update web and website modules; ignore if not installed
	docker compose exec odoo odoo -d $(ODOO_DB_NAME) -u web,website --stop-after-init || true

# Install Deonet test addons explicitly (optional helper)
install-deonet-addons: wait-for-db
	docker compose exec odoo odoo -d $(ODOO_DB_NAME) -i product_attribute_value_weight_odoo18_autosum_from_v1,product_template_attribute_value_opstartkosten_webshop --stop-after-init || true
