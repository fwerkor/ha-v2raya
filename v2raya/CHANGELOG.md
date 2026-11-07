# Changelog

## 0.2.0

- Downgrade v2rayA and matching v2raya_core to 2.4.0 to restore per-node AllowInsecure.
- Preserve existing add-on slug and LAN proxy ports; Home Assistant recognizes a new app update.
- Back up the existing SQLite database before first startup after downgrade.

## 0.1.1

- Add the upstream v2rayA icon and logo for the Home Assistant app store.
- Publish a pre-built multi-architecture image on GHCR so Home Assistant does not have to build from Docker Hub.
- Use a single multi-architecture image for amd64 and aarch64.

## 0.1.0

- First version built from v2rayA v2.5.13.
- Expose Web UI and LAN HTTP/SOCKS5 proxy ports.
- Persist configuration in the add-on data directory.
- Avoid host networking and transparent proxy privileges.
