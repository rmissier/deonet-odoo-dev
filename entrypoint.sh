#!/usr/bin/env bash
set -euo pipefail

# entrypoint.sh for Odoo container
# Always run Odoo with the provided config file

ODOO_BIN="/usr/bin/odoo"
ODOO_CONF="/etc/odoo/odoo.conf"
DEBUG_PORT="${DEBUG_PORT:-5678}"
DEBUG="${DEBUG:-0}"
DEBUG_WAIT="${DEBUG_WAIT:-0}"

run_odoo() {
  if [ "$#" -gt 0 ]; then
    exec "$ODOO_BIN" -c "$ODOO_CONF" "$@"
  else
    exec "$ODOO_BIN" -c "$ODOO_CONF"
  fi
}

if [ "$DEBUG" = "1" ]; then
  # Bootstrap debugpy manually to avoid CLI parsing issues.
  export ODOO_CONF
  exec python3 -Xfrozen_modules=off -u -c '
import os, sys, runpy
import debugpy
host = "0.0.0.0"
port = int(os.environ.get("DEBUG_PORT", "5678"))
debugpy.listen((host, port))
if os.environ.get("DEBUG_WAIT", "0") == "1":
    debugpy.wait_for_client()
# Build argv for the Odoo module: ["odoo", "-c", conf] + any extra args
conf = os.environ.get("ODOO_CONF", "/etc/odoo/odoo.conf")
sys.argv = ["odoo", "-c", conf] + sys.argv[1:]
runpy.run_module("odoo", run_name="__main__")
' "$@"
else
  run_odoo "$@"
fi
