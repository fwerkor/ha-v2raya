# Changelog

## 0.1.1

- Publish a pre-built multi-architecture image on GHCR so Home Assistant does not have to build from Docker Hub.
- Use a single multi-architecture image for amd64 and aarch64.

## 0.1.0

- First version built from v2rayA v2.5.13.
- Expose Web UI and LAN HTTP/SOCKS5 proxy ports.
- Persist configuration in the add-on data directory.
- Avoid host networking and transparent proxy privileges.
