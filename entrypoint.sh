#!/usr/bin/env bash
set -euo pipefail

# entrypoint.sh for Odoo container
# Always run Odoo with the provided config file

ODOO_BIN="/usr/bin/odoo"
ODOO_CONF="/etc/odoo/odoo.conf"

if [ "$#" -gt 0 ]; then
  exec "$ODOO_BIN" -c "$ODOO_CONF" "$@"
else
  exec "$ODOO_BIN" -c "$ODOO_CONF"
fi
