# Disaster Pi 🆘🥧
**The Offline Survival & Information Appliance**

![Status](https://img.shields.io/badge/Status-Prototype-orange) ![Docker](https://img.shields.io/badge/Docker-Compose-blue) ![Raspberry Pi](https://img.shields.io/badge/Hardware-RPI5-C51A4A)

Disaster Pi turns a Raspberry Pi 5 into a completely offline, air-gapped information hub. It provides medical encyclopedias, survival guides, repair manuals, topographic maps, and even a local AI coding assistant—all accessible via a Wi-Fi hotspot when the grid is down.

## 🌟 Features
* **Central Dashboard:** A clean homepage to access all services (`https://survival.lan`).
* **Offline Library (Kiwix):** Wikimed (Medical), iFixit (Repair), Appropedia (Sustainability), and Wikipedia.
* **Recipe Database (Mealie):** Store and organize food prep/ration recipes without internet.
* **Local AI (Ollama):** Optional integration with `qwen2.5:1.5b` or `phi-3` for offline reasoning and coding help.
* **File Server:** Drag-and-drop file storage for maps, PDFs, and binaries.
* **Smart DNS:** Automatic wildcard resolution (`*.survival.lan`)—no IP addresses to memorize.
* **Scripts:** There are utility scripts to initialize a basic survival library, backup your data, and backup the docker images. See [docs/user-guide.md](docs/user-guide.md) for details

## 🛠️ Hardware Requirements
* **Raspberry Pi 5** (8GB RAM recommended for AI features).
* **NVMe HAT + SSD:** Recommended over SD cards for database reliability.
* **Power Bank / Solar:** For true off-grid usage.

## 📋 Prerequisites
This project assumes you have already installed **RaspAP** on your Raspberry Pi to handle the Wi-Fi Hotspot creation.
* [RaspAP Installation Guide](https://docs.raspap.com/)

If you want to access the interface without connecting to the hotspot, you can add your Pi's IP to your system `hosts` file:
```
192.168.1.20 survival.lan # use the IP address from the interface you would like to access from, eth0 or wlan0
```
**NOTE:** this will override the "Magic" DNS provided by DNSMasq. You will not be able to access the dashboard while connected to the hotspot with this in your `hosts` file


## 🚀 Quick Start

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/mark3748/disaster-pi.git
    cd disaster-pi
    ```

2.  **Run the Installer**
    This script will configure Docker, fix RaspAP ports, and deploy the stack.
    ```bash
    sudo ./setup.sh
    ```
    *You will be asked if you want to enable the AI integration during setup.*

3.  **Access the System**
    Connect to your Pi's Wi-Fi hotspot and navigate to:
    * **Dashboard:** [https://survival.lan](https://survival.lan)
    * **Files:** [https://files.survival.lan](https://files.survival.lan)
    * **Admin:** [https://admin.survival.lan](https://admin.survival.lan) (RaspAP)

## 📂 Service Endpoints

| Service | URL | Description |
| :--- | :--- | :--- |
| **Homepage** | `https://survival.lan` | Main dashboard |
| **Kiwix** | `https://kiwix.survival.lan` | Offline Wikis & Medical Info |
| **Mealie** | `https://mealie.survival.lan` | Recipes & Meal Planning |
| **FileBrowser** | `https://files.survival.lan` | File Management |
| **Ollama** | `https://ai.survival.lan` | AI API (Optional) |

## 📚 Adding Content (ZIM Files)
To populate the offline library, you need `.zim` files.
1.  Run the helper script to download the essentials (Medical, Repair, Survival):
    ```bash
    ./scripts/download-standard-zims.sh
    ```
2.  Or manually place your own `.zim` files in `/opt/disaster-pi/files/zim-library`.
3.  Restart the Kiwix container: `docker restart disaster-pi-kiwix-1`

## 🔐 Credentials
* **FileBrowser:** The default password is generated on first launch.
    * Get it via: `docker compose logs filebrowser | grep admin`
* **Mealie:** Default: `changeme@example.com` / `MyPassword`
* **Postgres:** configured in `docker/compose.yaml` (Default: `secure_offline_password`).

## ⚠️ Notes
* **HTTPS:** This project uses self-signed certificates via Caddy's internal CA. You will get a browser warning on the first visit. This is normal for an offline `.lan` domain.
* **AI Performance:** On a Pi 5, the 1.5B model generates text at a readable speed. Heavier models (7B+) are not recommended.

## 📜 License
MIT License
