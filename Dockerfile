FROM odoo:18

# Install git and sudo, and allow the 'odoo' user to use sudo without a password
USER root
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git ca-certificates sudo \
    && usermod -aG sudo odoo \
    && echo 'odoo ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/odoo \
    && chmod 0440 /etc/sudoers.d/odoo \
    && rm -rf /var/lib/apt/lists/*

# Back to the default odoo user
USER odoo
