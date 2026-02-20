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
INSTALL_DIR="${INSTALL_DIR:-/opt/disaster-pi}"
AI_MODEL="qwen2.5:1.5b" # Change to 'phi-3' if preferred
DNS_DEST="/etc/dnsmasq.d/01-DNS-survival-lan.conf"
GITPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely read .env as data, bypassing execution vulnerabilities
if [ -f "$INSTALL_DIR/.env" ]; then
    echo "[+] Loading configuration from $INSTALL_DIR/.env"
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^#.* ]] || [[ -z "$key" ]] && continue
        
        # Strip potential surrounding single or double quotes from the value
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"
        
        # Safely assign and export the variable
        export "$key=$value"
    done < "$INSTALL_DIR/.env"
fi

# Set defaults if not loaded from .env
ENABLE_AI=${ENABLE_AI:-false}
ENABLE_DOCKING=${ENABLE_DOCKING:-false}
PG_ADMIN_PASSWORD=${PG_ADMIN_PASSWORD:-disasterpiadmin}

# --- Whiptail Menu System ---

# Ensure whiptail is available
if ! command -v whiptail &> /dev/null; then
    echo "[!] whiptail not found. Installing..."
    apt-get update && apt-get install -y whiptail
fi

# 1. Prompt for AI
AI_MSG="Enable AI Integration?\n\nNot recommended for anything below a Pi 5 8GB. This will install Ollama and Open WebUI.\n\nCurrent Status: $( [[ $ENABLE_AI == true ]] && echo "ENABLED" || echo "DISABLED" )"
if [[ $ENABLE_AI == true ]]; then
    if whiptail --title "AI Integration" --yesno "$AI_MSG" 12 60; then
        ENABLE_AI=true
    else
        ENABLE_AI=false
    fi
else
    if whiptail --title "AI Integration" --yesno "$AI_MSG" 12 60 --defaultno; then
        ENABLE_AI=true
    else
        ENABLE_AI=false
    fi
fi

# 2. Prompt for Docking Mode
DOCK_MSG="Enable Docking Mode?\n\nRuns update script when eth0 connects. Recommended for portable 'field' units that sync when returned to base.\n\nCurrent Status: $( [[ $ENABLE_DOCKING == true ]] && echo "ENABLED" || echo "DISABLED" )"
if [[ $ENABLE_DOCKING == true ]]; then
    if whiptail --title "Docking Mode" --yesno "$DOCK_MSG" 12 60; then
        ENABLE_DOCKING=true
    else
        ENABLE_DOCKING=false
    fi
else
    if whiptail --title "Docking Mode" --yesno "$DOCK_MSG" 12 60 --defaultno; then
        ENABLE_DOCKING=true
    else
        ENABLE_DOCKING=false
    fi
fi

# 3. Prompt for Postgres Password
PG_ADMIN_PASSWORD_TMP=$(whiptail --title "Database Security" --inputbox "Enter desired Postgres 'admin' user password:" 10 60 "$PG_ADMIN_PASSWORD" 3>&1 1>&2 2>&3)
if [ $? -eq 0 ]; then
    PG_ADMIN_PASSWORD="$PG_ADMIN_PASSWORD_TMP"
fi

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
mkdir -p "$INSTALL_DIR"/{files/zim-library,docker,homepage,mealie-data,pgdata,scripts,ollama_data,open-webui-data,homebox-data,logs}

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

if [[ $ENABLE_DOCKING == true ]]; then
    echo "[+] Enabling Docking Mode..."
    cp "$INSTALL_DIR/scripts/99-docking-mode.sh" /etc/NetworkManager/dispatcher.d/99-docking-mode
    chown root:root /etc/NetworkManager/dispatcher.d/99-docking-mode
    chmod 755 /etc/NetworkManager/dispatcher.d/99-docking-mode
    systemctl enable --now NetworkManager-dispatcher.service # Ensure the dispatcher service is running or the script won't run when the interface comes up.
else
    echo "[+] Disabling Docking Mode..."
    rm -f /etc/NetworkManager/dispatcher.d/99-docking-mode
fi

# FORCE PERMISSIONS for User 1000
echo "[+] Enforcing 1000:1000 ownership on data directories..."
chown -R 1000:1000 "$INSTALL_DIR"
echo "[+] Fixing Postgres permissions..."
chown -R 999:999 "$INSTALL_DIR/pgdata"
echo "[+] Fixing Mealie permissions..."
chown -R 911:911 "$INSTALL_DIR/mealie-data"
echo "[+] Fixing Homebox permissions..."
chown -R 65532:65532 "$INSTALL_DIR/homebox-data"
chmod -R 775 "$INSTALL_DIR/homebox-data"
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
    printf "%s=%q\n" "PG_ADMIN_PASSWORD" "$PG_ADMIN_PASSWORD"
    printf "%s=%q\n" "ENABLE_AI" "$ENABLE_AI"
    printf "%s=%q\n" "ENABLE_DOCKING" "$ENABLE_DOCKING"
    printf "%s=%q\n" "GITPATH" "$GITPATH"
    printf "%s=%q\n" "INSTALL_DIR" "$INSTALL_DIR"
} > "$INSTALL_DIR/.env"
chmod 600 "$INSTALL_DIR/.env" # Make it readable only by root/owner

# 4. Launch Stack
cd "$INSTALL_DIR"
if [[ $ENABLE_AI == true ]]; then
    echo "[+] Launching Stack (Standard + AI)..."
    cp ./docker/compose.yaml ./docker/compose.ai.yaml .
    docker compose -f compose.yaml -f compose.ai.yaml up -d --remove-orphans
else
    echo "[+] Launching Stack (Standard)..."
    cp ./docker/compose.yaml .
    docker compose up -d --remove-orphans
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