# CN Mirror installation variant

This optional variant pulls the **same** released 0.2.0 binary image through `ghcr.dockerproxy.net`, a third-party image proxy, instead of directly from `ghcr.io`. The `v0.1.1` OCI image index and both platform manifests were compared with official GHCR on 2026-11-07 and had identical SHA-256 digests. A third-party proxy is not under our control: use the official app where possible. This does **not** cure failures fetching the GitHub app repository itself. For that failure use the local recovery installer described in the repository README.

Do not install both the standard and CN variants at the same time because their host network ports conflict. They have separate app data and no automatic migration.

# v2rayA Proxy

Run v2rayA on Home Assistant OS and share HTTP/SOCKS5 proxy services on a trusted LAN. This add-on uses isolated container networking, never transparent-proxies HAOS itself, and requires no privileged capabilities. Version 0.2.0 installs a prebuilt multi-architecture image from GHCR and does not require HAOS to contact Docker Hub for local builds.

## Setup

1. Add `https://github.com/fwerkor/ha-v2raya` in **Settings → Add-ons → Add-on Store → Repositories** (may be labeled *Apps*).
2. Install and start **v2rayA Proxy**. Open its Web UI or navigate to `http://<HA_IP>:2017`.
3. Create a strong v2rayA admin password; import a subscription / add a server, select it and press **Start**.
4. Open v2rayA **Settings**, enable **LAN Sharing**, then restart its proxy connection if needed. Mapping the ports in Home Assistant alone does not enable external proxy listeners.
5. Configure a device on the allowed LAN using the HAOS host IP (not the HA container IP):

| Type | Address | Notes |
| --- | --- | --- |
| SOCKS5 | `socks5://<HA_IP>:20170` | `socks5h` makes clients resolve DNS through proxy |
| HTTP | `http://<HA_IP>:20171` | Standard HTTP/HTTPS proxy |
| Routed HTTP | `http://<HA_IP>:20172` | Applies v2rayA routing/shunt rules |
| Web UI | `http://<HA_IP>:2017` | Admin only, not a proxy |

Example:

```sh
curl -x socks5h://192.168.1.10:20170 https://www.example.com/
curl -x http://192.168.1.10:20171 https://www.example.com/
```

## Safety and network

The Network section allows changing or disabling host port mappings. Port `2017` exposes the administration UI; protect it with a strong password and router/VLAN firewall rules. Proxy ports are **not authenticated by default**: any machine that can reach them can use your upstream proxy. **Never forward them to the public Internet.** Make them accessible only to trusted LAN hosts. This add-on does not enable a proxy for Home Assistant itself, does not edit HAOS routing, and does not request NET_ADMIN, host networking or full access. Do not enable transparent proxy mode in the v2rayA UI.

## Data and troubleshooting

State persists under the add-on's `/data/v2raya`. Protect HA backups because subscriptions may contain credentials. If a client cannot connect: check the Network mappings, running upstream node, v2rayA LAN Sharing option, host IP, VLAN/router firewall and add-on logs. v2rayA and its matching core are upstream 2.4.0 release binaries verified against upstream SHA-256 checksums.

## Host proxy

The CN mirror also leaves Supervisor and the Docker daemon unmodified. See the [HAOS host proxy guide](https://github.com/fwerkor/ha-v2raya/blob/main/docs-host-proxy.md).

## v2rayA 2.4.0 / AllowInsecure

The add-on version is **0.2.0**, and both its `v2raya` and `v2raya_core` binaries are **2.4.0**. This is the last verified upstream release supporting the per-node **AllowInsecure** switch in the server editor. It weakens TLS authentication and is off by default. Keep it off unless a specific upstream server requires it. Upgrading from an add-on that used v2rayA 2.5.13 is a runtime downgrade: a one-time database snapshot is saved as `v2raya-pre-2.4.0.db` before first launch, but you should also create a Home Assistant backup before the update. Newer 2.5-only features/configurations may not be recognized by 2.4.0.
