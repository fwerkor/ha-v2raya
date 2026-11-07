# v2rayA Proxy

Run v2rayA on Home Assistant OS and share HTTP/SOCKS5 proxy services on a trusted LAN. This add-on uses isolated container networking, never transparent-proxies HAOS itself, and requires no privileged capabilities.

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

State persists under the add-on's `/data/v2raya`. Protect HA backups because subscriptions may contain credentials. If a client cannot connect: check the Network mappings, running upstream node, v2rayA LAN Sharing option, host IP, VLAN/router firewall and add-on logs. v2rayA and core are supplied by the upstream `mzz2017/v2raya:v2.5.13` image.
