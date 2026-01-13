# Bill of Materials (BOM)

This build is designed around the **Raspberry Pi 5** due to its PCIe capabilities, which allow for high-speed, reliable NVMe storage—critical for hosting large databases and AI models without the SD card corruption risks of older Pis.

## Core Computing
| Component | Specification | Why this? | Estimated Cost |
| :--- | :--- | :--- | :--- |
| **SBC** | Raspberry Pi 5 (8GB) | 8GB RAM is **mandatory** for running the LLM (AI) and Postgres simultaneously. | ~$80 |
| **Cooling** | Active Cooler | The Pi 5 runs hot; passive cooling is insufficient for AI workloads. | ~$5 |
| **Storage** | NVMe SSD (512GB+) | Database reliability. SD cards die under database write loads. 512GB allows for ~300GB of ZIM files. | ~$40 |
| **Interface** | NVMe HAT (PCIe) | Connects the SSD. *Examples: Pineberry Pi HatDrive, Geekworm X1000.* | ~$15 |

## Power & Case
| Component | Specification | Notes |
| :--- | :--- | :--- |
| **Power Supply** | 27W USB-C PD | The Pi 5 requires 5V/5A for full peripheral power (NVMe + USB drives). Standard phone chargers will cause brownouts. |
| **Battery** | USB-C PD Power Bank | Must support **pass-through charging** (UPS mode) to keep the Pi running while the battery charges from solar. |
| **Case** | Open or Vented | Avoid sealed cases. The AI model pins the CPU at 100%; airflow is critical. |

## Recommended Peripherals
* **USB Wi-Fi Adapter (Optional):** If you want to use the internal Wi-Fi for client connections (Hotspot) and need a second interface to scan for external networks.
* **USB Drive (128GB):** For "Cold Storage" backups of your Docker images and ZIM files.