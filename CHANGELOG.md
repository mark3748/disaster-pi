# Changelog

All notable changes to the Disaster Pi project will be documented in this file.

## [Unreleased]

### Features
- Added an image-based backup option for full system backups using `image-backup`.
- Added `restore-backup.sh` script for easy restoration of backups.
- Added utility scripts for daily backups (`backup-daily.sh`) and image freezing (`freeze-images.sh`).
- Added initial Bill of Materials (BOM) and User Guide in `docs/`.
- Added local icons for the homepage dashboard to ensure offline availability.
- Enhanced download function with checksum verification and resume capability.
- Initial project setup including README, Caddy/DNS configurations, and Docker Compose files.

### Bug Fixes
- Corrected `compose.yaml` path in backup script to ensure database dumps function correctly.
- Fixed homepage config syntax and normalized icon naming conventions.
- Resolved issues with `raspap` icon by switching to PNG format.
- Improved robustness of download scripts:
    - Added error handling.
    - Quoted variable expansions for reliability.
    - Corrected syntax errors in ZIM file download commands.
- Fixed Postgres service configuration by adding default database environment variable.
- Corrected permissions for Mealie data directory.
- Fixed volume mount paths for homepage configuration persistence.
- Corrected DNS destination paths and reload logic in setup scripts.
- Fixed various bugs in the `setup.sh` script (filenames, directory inclusion).

### Documentation
- Updated User Guide and scripts for better clarity and consistency in paths.
- Fixed formatting of the clone command in the README.

### Configuration & Maintenance
- Updated Caddyfile and Docker Compose for Open WebUI integration.
- Updated homepage default configurations.
- Updated ZIM file download links to latest versions.
