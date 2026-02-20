# Project Roadmap

The following is a living document of the wants, needs, and "wouldn't it be cool if" features for Disaster Pi. Priorities are subject to change based on hardware availability and the encroaching apocalypse.

## 🛠️ Phase 1: Operational Refinement (v1.1 - v1.2)

*Focus: Stability, Usability, and Logistics.*

* [x] **Inventory System (Logistics):** Implementation of **HomeBox** to track physical assets (batteries, meds, spare parts). *Status: Done.*
* [ ] **SDR Integration (Signal Intel):** Support for RTL-SDR v3 dongles via OpenWebRX+ or similar. Turn the Pi into a spectrum scanner for weather, police, and HAM bands.
* [x] **"Docking Mode" (formerly "Scavenger Mode"):** A NetworkManager dispatcher script that detects an active internet connection (Ethernet/Uplink) and automatically runs:
    * `docker compose pull` (Update images)
    * `apt update && apt upgrade` (Patch OS)
    * `git pull` (Update scripts)
    * sync updated scripts and config files to the production directory from git
    **STATUS: Completed**
    Setup allows for optional enabling of this feature. Script updates all components automatically.


* [ ] **Interactive Setup (TUI):** Migrate `setup.sh` to a menu-driven interface (using `whiptail` or `dialog`). As the stack grows (AI, SDR, Inventory), users need to toggle modules ON/OFF easily without editing YAML.
* [ ] **Watchdog Services:** A systemd service to monitor container health and auto-heal the stack if the Docker daemon hangs.

## 📡 Phase 2: Hardware & Expansion

*Focus: Physical resiliency and off-grid comms.*

* [ ] **Meshtastic Integration:** A "tethered" mode for LoRa radios. Use the Pi to host a local Meshtastic map or bridge messages to the AI for summarization.
* [ ] **Hardware Documentation:**
    * NVMe assembly guides (HAT compatibility list).
    * Power management (UPS/Battery/Solar recommendations).
    * 3D printable case files or links to rugged enclosures.
* [ ] **Cyberdeck Plugins:** Fun hardware integration, like using an ESP32 to display system stats (CPU load, Battery voltage) on a small OLED screen mounted to the case.

## 🧪 Phase 3: "The Crazy Stuff" (Experimental)

*Features that push the limits of the hardware or sanity.*

* [ ] **GIS / Tile Server:** Hosting a vector tile server (TileServer GL) for zoomable, street-level topographic maps. Kiwix maps are okay, but a true interactive map server would be a game-changer for navigation.
* [ ] **Morale Module (Media):** Jellyfin or Navidrome for serving music/movies. Psychological well-being is a survival stat too.
* [ ] **LAN Party Server:** Pre-configured game servers (Doom, Minecraft, Quake) that can spin up on demand.
* [ ] **Environmental Sensors:** Integration with DHT11/BME280 sensors to log temperature, humidity, and air quality directly to the dashboard. Know if your shelter is safe.
