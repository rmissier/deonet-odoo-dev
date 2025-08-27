#!/bin/bash
# Clone Odoo branches from different repos into specific folders using .env variables

set -e

# Load .env variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found!"
    exit 1
fi

echo "Cloning Odoo Enterprise..."
git clone -b "$ENTERPRISE_BRANCH" "$GIT_ENTERPRISE_REPO" "$ODOO_ENTERPRISE_PATH"

echo "Cloning test addons..."
git clone -b "$ADDONS_TEST_BRANCH" "$GIT_CUSTOM_REPO" "$ADDONS_TEST_PATH"

echo "Cloning my feature branch..."
git clone -b "$ADDONS_MY_BRANCH" "$GIT_CUSTOM_REPO" "$ADDONS_MY_PATH"

echo "All repositories cloned successfully."
