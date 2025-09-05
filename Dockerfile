FROM odoo:18.0

USER root

# Install minimal useful utilities including sudo for development
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates ssh-client curl nano python3-debugpy sudo \
    && rm -rf /var/lib/apt/lists/*

# Add odoo user to sudo group and configure passwordless sudo for development
RUN usermod -aG sudo odoo \
    && echo "odoo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/odoo \
    && chmod 0440 /etc/sudoers.d/odoo

# Set up SSH directory for odoo user
RUN mkdir -p /var/lib/odoo/.ssh \
    && chown odoo:odoo /var/lib/odoo/.ssh \
    && chmod 700 /var/lib/odoo/.ssh

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set working directory
WORKDIR /opt/odoo

USER odoo

ENTRYPOINT ["/entrypoint.sh"]