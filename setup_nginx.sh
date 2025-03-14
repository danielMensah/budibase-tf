#!/bin/bash
# This script sets up SSL directories, installs and configures Nginx with an origin certificate and key.
# It loads configuration exclusively from a YAML file (default is config.yaml, or via the -c option).
#
# Usage:
#   ./setup_nginx.sh -c myconfig.yaml  # Uses the specified YAML configuration file.
#
# Requirements:
#   - yq (https://github.com/mikefarah/yq) is required. Running this script will attempt to install yq if not found.
#
# Sample YAML file structure is provided below.

set -euo pipefail

# Determine the config file to use.
if [[ $# -gt 0 && "$1" == "-c" ]]; then
    CONFIG_FILE="$2"
else
    CONFIG_FILE="config.yaml"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file not found: $CONFIG_FILE"
    exit 1
fi

# Check if yq is installed; if not, attempt to install it.
if ! command -v yq &> /dev/null; then
    echo "yq not found. Installing yq..."
    # Download the latest yq Linux binary (adjust version if needed).
    sudo wget -q https://github.com/mikefarah/yq/releases/download/v4.34.1/yq_linux_amd64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
    echo "yq installed successfully."
fi

# Load values from the YAML configuration file.
SITE_HOST=$(yq e '.site.host' "$CONFIG_FILE")
ORIGIN_CERT=$(yq e '.site.origin_cert' "$CONFIG_FILE")
ORIGIN_KEY=$(yq e '.site.origin_key' "$CONFIG_FILE")

if [[ -z "$SITE_HOST" || -z "$ORIGIN_CERT" || -z "$ORIGIN_KEY" ]]; then
    echo "YAML configuration file must define site.host, site.origin_cert, and site.origin_key."
    exit 1
fi

echo "Setting up SSL directories and files..."
sudo mkdir -p /etc/ssl/certs
sudo mkdir -p /etc/ssl/private

# Write the certificate and key to the appropriate files.
echo "$ORIGIN_CERT" | sudo tee /etc/ssl/certs/origin_cert.pem > /dev/null
echo "$ORIGIN_KEY" | sudo tee /etc/ssl/private/origin_key.pem > /dev/null

sudo chmod 600 /etc/ssl/private/origin_key.pem
sudo chown root:root /etc/ssl/private/origin_key.pem

echo "Installing and configuring Nginx..."
sudo apt update && sudo apt install nginx -y
sudo nginx -t

# Create the Nginx configuration for the site.
NGINX_CONF="/etc/nginx/sites-available/${SITE_HOST}"
sudo bash -c "cat > ${NGINX_CONF}" <<EOF
server {
    listen 80;
    server_name ${SITE_HOST} www.${SITE_HOST};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name ${SITE_HOST} www.${SITE_HOST};

    client_max_body_size 500M;

    ssl_certificate /etc/ssl/certs/origin_cert.pem;
    ssl_certificate_key /etc/ssl/private/origin_key.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /ws/ {
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the site by creating a symbolic link.
sudo ln -s "${NGINX_CONF}" /etc/nginx/sites-enabled/

sudo nginx -t
sudo systemctl restart nginx

echo "Updating firewall rules..."
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp
sudo ufw reload

echo "Setup completed successfully."
