#!/bin/bash
## Setup script for Disaster Pi, a preparedness software stack designed to be useful for an "off-the-grid" scenario.
## For details see https://mhamburger.net/projects/disaster-pi or https://github.com/mark3748/disaster-pi

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./setup.sh)"
  exit 1
fi

set -e

# Configuration
INSTALL_DIR="/opt/disaster-pi"
AI_MODEL="qwen2.5:1.5b" # Change to 'phi-3' if preferred
DNS_DEST="/etc/dnsmasq.d/01-DNS-survival-lan.conf"

# --- Prompt for AI ---
## Ensure your device is capable before enabling AI features. See README for details.
read -r -p "${ENABLE_AI:-Enable AI Integration (Not recommended for anything below a Pi 5 8GB). (y/N) } " REPLY
REPLY=${REPLY:-n}
case "$REPLY" in
    [Yy]* ) ENABLE_AI=true ;;
    [Nn]* ) ENABLE_AI=false ;;
esac

#--- Prompt for Postgres Password ---
read -r -p "Enter desired Postgres 'admin' user password (default: 'disasterpiadmin'): " INPUT_PG_PASSWORD
PG_ADMIN_PASSWORD=${INPUT_PG_PASSWORD:-disasterpiadmin}

echo "--- Disaster Pi Setup Initiated ---"

## Stage 1: Setup system, get Docker enabled and all that jazz.
# 1. Install Dependencies & Docker
echo "[+] Checking dependencies..."
apt-get update && apt-get install -y curl git acl

if ! command -v docker &> /dev/null; then
    echo "[+] Docker not found. Installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    usermod -aG docker $USER
    echo "[+] Docker installed."
else
    echo "[+] Docker already installed."
fi

# 2. RaspAP Port Fix (Lighttpd)
LIGHTTPD_CONF="/etc/lighttpd/lighttpd.conf"
if [ -f "$LIGHTTPD_CONF" ]; then
    echo "[+] RaspAP (lighttpd) detected. Checking port configuration..."
    if grep -q "server.port.*=.*8000" "$LIGHTTPD_CONF"; then
        echo "[+] Port already set to 8000."
    else
        echo "[+] Moving RaspAP to port 8000 to free port 80 for Caddy..."
        sed -i 's/server.port.*=.*/server.port                 = 8000/g' "$LIGHTTPD_CONF"
        systemctl restart lighttpd
        echo "[+] Lighttpd restarted on port 8000."
    fi
else
    echo "[!] WARNING: RaspAP configuration not found at $LIGHTTPD_CONF."
    echo "    Ensure RaspAP is installed if you want the Hotspot functionality."
fi

# 3. Create Directories & Fix Permissions
echo "[+] Creating project directories..."
mkdir -p "$INSTALL_DIR"/{files/zim-library,docker,homepage,mealie-data,pgdata,scripts,ollama_data,open-webui-data}

# Copy Configs
echo "[+] Copying configurations..."
cp -r ./configs/Caddyfile "$INSTALL_DIR/Caddyfile"
cp -r ./configs/init-multiple-dbs.sh "$INSTALL_DIR/init-multiple-dbs.sh"
cp -r ./configs/dnsmasq.conf "$DNS_DEST"
cp -r ./homepage "$INSTALL_DIR/"
cp -r ./docker "$INSTALL_DIR/"
echo "[+] Installing helper scripts..."
cp -r ./scripts/* "$INSTALL_DIR/scripts/"
# Make scripts executable
chmod +x "$INSTALL_DIR/scripts/"*.sh
chmod +x "$INSTALL_DIR/init-multiple-dbs.sh"

# FORCE PERMISSIONS for User 1000
echo "[+] Enforcing 1000:1000 ownership on data directories..."
chown -R 1000:1000 "$INSTALL_DIR"
echo "[+] Fixing Postgres permissions..."
chown -R 999:999 "$INSTALL_DIR/pgdata"
echo "[+] Fixing Mealie permissions..."
chown -R 911:911 "$INSTALL_DIR/mealie-data"
# Required for AI, running regardless of AI option for UX reasons. 
# If you change deployment mode later, they'll be set!
echo "[+] chmod 777 to AI data directories..."
chmod 777 "$INSTALL_DIR/ollama_data"
chmod 777 "$INSTALL_DIR/open-webui-data"

# Reload NetworkManager for DNS
if systemctl is-active --quiet dnsmasq; then
    systemctl reload dnsmasq
fi

# Save .env File before launching stack
echo "[+] Saving .env configuration..."
{
    echo "PG_ADMIN_PASSWORD=$PG_ADMIN_PASSWORD"
    echo "ENABLE_AI=$ENABLE_AI"
} >> $INSTALL_DIR/.env
chmod 600 "$INSTALL_DIR/.env" # Make it readable only by root/owner

# 4. Launch Stack
cd "$INSTALL_DIR"
if [[ $ENABLE_AI == true ]]; then
    echo "[+] Launching Stack (Standard + AI)..."
    cp ./docker/compose.yaml ./docker/compose.ai.yaml .
    docker compose -f compose.yaml -f compose.ai.yaml up -d
else
    echo "[+] Launching Stack (Standard)..."
    cp ./docker/compose.yaml .
    docker compose up -d
fi

# 5. AI Model Pull (Conditional)
if [[ $ENABLE_AI == true ]]; then
    echo "[+] Waiting for Ollama..."
    sleep 10
    echo "[+] Pulling Model: $AI_MODEL..."
    docker compose exec ollama ollama pull "$AI_MODEL"
fi


# 6. Final Instructions
echo "--- Setup Complete! ---"
echo "Dashboard: https://survival.lan"
echo "Admin:     https://admin.survival.lan"
if [[ $ENABLE_AI == true ]]; then
    echo "AI Access: https://ai.survival.lan"
fi
echo "Don't forget to grab your File Browser password via: docker compose logs filebrowser | grep admin"