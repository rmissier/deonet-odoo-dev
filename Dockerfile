FROM odoo:18.0

USER root

# Install minimal useful utilities; avoid sudo and debugging packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates ssh-client curl nano python3-debugpy \
    && rm -rf /var/lib/apt/lists/*

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set working directory
WORKDIR /opt/odoo

USER odoo

ENTRYPOINT ["/entrypoint.sh"]