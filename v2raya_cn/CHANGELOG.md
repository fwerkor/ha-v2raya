# Changelog

## 0.2.0

- Downgrade v2rayA and matching v2raya_core to 2.4.0 to restore per-node AllowInsecure.
- Preserve existing add-on slug and LAN proxy ports; Home Assistant recognizes a new app update.
- Back up the existing SQLite database before first startup after downgrade.

## 0.1.1

- Initial CN Mirror variant. Uses ghcr.dockerproxy.net to proxy the same multi-architecture upstream image.
