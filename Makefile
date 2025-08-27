.PHONY: filestore
wait-for-db:
	@echo "⏳ Waiting for database to be ready..."
	@until docker compose exec -T db pg_isready -U $(POSTGRES_USER) -d $(ODOO_DB_NAME); do \
		sleep 1; \
	done
# Load variables from .env
include .env
export $(shell sed 's/=.*//' .env)

.DEFAULT_GOAL := start

start: filestore pull-code checkout-branches up maybe-restore-db

pull-code:
	@echo "🔄 Pulling latest Enterprise..."
	cd $(ODOO_ENTERPRISE_PATH) && git fetch && git pull
	@echo "🔄 Pulling latest addons-test..."
	cd $(ADDONS_TEST_PATH) && git fetch && git pull
	@echo "🔄 Pulling latest addons-mybranch..."
	cd $(ADDONS_MY_PATH) && git fetch && git pull

checkout-branches:
	@echo "🔀 Checking out Enterprise branch: $(ENTERPRISE_BRANCH)"
	cd $(ODOO_ENTERPRISE_PATH) && git checkout $(ENTERPRISE_BRANCH)
	@echo "🔀 Checking out addons-test branch: $(ADDONS_TEST_BRANCH)"
	cd $(ADDONS_TEST_PATH) && git checkout $(ADDONS_TEST_BRANCH)
	@echo "🔀 Checking out addons-mybranch branch: $(ADDONS_MY_BRANCH)"
	cd $(ADDONS_MY_PATH) && git checkout $(ADDONS_MY_BRANCH)

filestore:
	@echo "🔀 Copy filestore"
	rm -rf ./filestore
	cp -r "${ODOO_BACKUP_PATH}/filestore" ./

up:
	docker compose up -d

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
