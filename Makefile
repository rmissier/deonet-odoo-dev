
.PHONY: filestore url start up reset-addons reset-db wait-for-db odoo-logs update-apps-list db-shell odoo-shell nuke rebuild-assets tidy smoke debug debug-wait debug-off scaffold install-deps

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
start: reset-addons up install-deps smoke


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

# Start Odoo with debug adapter active (port 5678)
debug:
	@echo "🐞 Starting Odoo in debug mode (port 5678)..."
	DEBUG=1 docker compose up -d --build odoo
	@echo "Attach from VS Code using '.vscode/launch.json' → 'Attach to Odoo (debugpy)'."

# Start Odoo in debug mode and wait for debugger to attach before running
debug-wait:
	@echo "🐞 Starting Odoo in debug WAIT mode (port 5678)..."
	DEBUG=1 DEBUG_WAIT=1 docker compose up -d --build odoo
	@echo "Odoo will wait for debugger to attach before continuing."

# Turn off debug (recreate container without DEBUG)
debug-off:
	@echo "🧹 Restarting Odoo without debug..."
	DEBUG=0 DEBUG_WAIT=0 docker compose up -d --build odoo

# Scaffold a new Odoo module in addons_my (usage: make scaffold NAME=my_module)
scaffold:
	@if [ -z "$(NAME)" ]; then echo "Usage: make scaffold NAME=my_module"; exit 2; fi
	@set -e; dest="./addons_my/$(NAME)"; \
	if [ -d "$$dest" ]; then echo "❌ Module exists: $$dest"; exit 1; fi; \
	mkdir -p "$$dest/models" "$$dest/security" "$$dest/views"; \
	echo "# -*- coding: utf-8 -*-\n{\n    'name': '$(NAME)',\n    'version': '16.0.1.0.0',\n    'depends': ['base'],\n    'data': [\n        'security/ir.model.access.csv',\n        'views/$(NAME)_views.xml'\n    ],\n    'license': 'LGPL-3',\n}" > "$$dest/__manifest__.py"; \
	echo "# -*- coding: utf-8 -*-\nfrom . import models" > "$$dest/__init__.py"; \
	echo "# -*- coding: utf-8 -*-\nfrom odoo import models, fields\n\nclass $(NAME:%=%s=)_model(models.Model):\n    _name = '$(NAME).model'\n    name = fields.Char()\n" | sed 's/%s/_/g' > "$$dest/models/__init__.py"; \
	echo "id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink\naccess_$(NAME)_model,$(NAME) model,model_$(NAME)_model,base.group_user,1,1,1,1" > "$$dest/security/ir.model.access.csv"; \
	echo "<odoo>\n  <record id=\"view_$(NAME)_model_tree\" model=\"ir.ui.view\">\n    <field name=\"name\">$(NAME).model.tree</field>\n    <field name=\"model\">$(NAME).model</field>\n    <field name=\"arch\" type=\"xml\">\n      <tree>\n        <field name=\"name\"/>\n      </tree>\n    </field>\n  </record>\n</odoo>" > "$$dest/views/$(NAME)_views.xml"; \
	echo "✅ Scaffolded $$dest"; \
	echo "🔧 Now run: docker compose exec odoo odoo -c /etc/odoo/odoo.conf -d $(DB_NAME) -u $(NAME) --stop-after-init || true";

# Install dependencies using script in addons_my directory
install-deps:
	@if [ ! -f "./addons_my/install_dependencies.sh" ]; then \
		echo "❌ Script ./addons_my/install_dependencies.sh not found!"; \
		exit 1; \
	fi
	@echo "📦 Installing dependencies from addons_my/install_dependencies.sh..."
	@docker compose exec odoo bash -c "chmod +x /mnt/addons_my/install_dependencies.sh && /mnt/addons_my/install_dependencies.sh"
	@echo "✅ Dependencies installed successfully"

reset-db: wait-for-db
	@if [ ! -f "./backup/dump.sql" ]; then \
		echo "❌ Database dump file ./backup/dump.sql not found!"; \
		exit 1; \
		fi
	@echo "🛑 Stopping Odoo service to free DB connections..."
	-@docker compose stop odoo || true
	@echo "🔪 Terminating active connections to $(DB_NAME)..."
	@docker compose exec -T db psql -U $(DB_USER) -d postgres -v ON_ERROR_STOP=1 -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$(DB_NAME)' AND pid <> pg_backend_pid();" || true
	@echo "🗑️ Dropping database $(DB_NAME)..."
	-@docker compose exec -T db dropdb --force -U $(DB_USER) $(DB_NAME) || docker compose exec -T db dropdb -U $(DB_USER) $(DB_NAME) || true
	@echo "🆕 Creating database $(DB_NAME)..."
	@docker compose exec -T db createdb -U $(DB_USER) $(DB_NAME)
	@echo "📥 Restoring ./backup/dump.sql into $(DB_NAME)..."
	@cat ./backup/dump.sql | docker compose exec -T db psql -U $(DB_USER) -d $(DB_NAME)
	@echo "🔧 Running Odoo upgrade in a one-off container..."
	@docker compose run --rm --entrypoint /usr/bin/odoo odoo -c /etc/odoo/odoo.conf -d $(DB_NAME) -u all --stop-after-init
	@echo "🚀 Starting Odoo service..."
	@docker compose up -d odoo


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

# Quick HTTP smoke test to ensure Odoo is up and assets are served
smoke:
	@echo "🔎 Smoke test: /web/login and frontend assets"
	@LOGIN_CODE=$$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8069/web/login); \
	ASSETS_CODE=$$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8069/web/assets/debug/web.assets_frontend.css); \
	echo "login: $$LOGIN_CODE"; \
	echo "assets: $$ASSETS_CODE"; \
	if [ "$$LOGIN_CODE" = "200" ] && [ "$$ASSETS_CODE" = "200" ]; then \
		echo "✅ Smoke check passed"; \
	else \
		echo "❌ Smoke check failed"; \
		exit 1; \
	fi
