# Using the v2rayA proxy from Home Assistant OS itself

The app provides explicit HTTP and SOCKS5 proxy ports for clients on your LAN, including processes on the HAOS host **that are explicitly configured to use them**. It does **not** automatically configure Home Assistant Core, Supervisor, Docker Engine, or host-wide routing. This distinction matters when GitHub or container registries are unreachable.

## Check the proxy from a Terminal & SSH app

1. Install and start v2rayA Proxy (or the CN variant), choose a working upstream node, and enable **LAN Sharing** in the v2rayA settings.
2. Find the actual HAOS host IP in **Settings → System → Network**. Use its LAN address, for example `192.168.1.10`; `127.0.0.1` inside a Terminal app points to that *app container*, not to the HAOS host.
3. Download [scripts/check-host-proxy.sh](scripts/check-host-proxy.sh) and run:

   ```sh
   sh check-host-proxy.sh 192.168.1.10 20171
   ```

   The script performs ordinary HTTP CONNECT requests to GitHub, GHCR and Docker Hub through the v2rayA HTTP proxy. `200`/`401` for the appropriate endpoints is evidence of outbound proxy connectivity, **not proof that Supervisor or Docker is proxying**.

## Optional explicit proxy for individual processes

Some programs (such as `curl`, `git`, and selected integrations) can use:

```sh
export HTTP_PROXY=http://192.168.1.10:20171
export HTTPS_PROXY=http://192.168.1.10:20171
export NO_PROXY=localhost,127.0.0.1,::1,homeassistant,supervisor,hassio,172.30.32.0/23,192.168.1.0/24
curl -I https://github.com/
```

Replace `192.168.1.10` and `192.168.1.0/24` with your real network. Do not export these values for Home Assistant's internal API connections or LAN device integrations unless you understand the no-proxy exceptions. This applies to **that shell and its child processes only**; it does not change the Supervisor or Docker daemon.

## Why the HAOS host and Supervisor are different

- **Docker Engine downloads images** as a host service, and needs its *own* daemon-level proxy configuration. Exporting `HTTPS_PROXY` in Terminal, or editing a single app's config, does not affect the Docker daemon.
- **Supervisor fetches app repositories** from its separate container. Its Git and HTTPS requests need an appropriate configuration at Supervisor creation/startup or a network-level gateway. The v2rayA app cannot change the environment of a running Supervisor container.
- **HAOS system upgrades and other network traffic** are distinct services. An HTTP proxy does not transparently redirect all IP packets or DNS traffic.
- **Home Assistant OS** has a read-only base filesystem; generic `/etc/docker/daemon.json` changes and custom systemd units are **not** supported persistent configuration mechanisms in HAOS. Avoid scripts that restart Docker or add iptables routes on the live HAOS host; they can disconnect your HA instance, break Supervisor, or leave the device unbootable after an update.

### What can be configured safely?

For a **Home Assistant Supervised install on a standard Linux host**, the host administrator can configure Docker's documented `proxies` in `/etc/docker/daemon.json` and restart Docker during a planned maintenance window. If you do this, take a backup, use the HAOS host's non-loopback IP as the proxy address, and keep internal network destinations in `no-proxy`. This is **not** a supported method for HAOS. See the [Docker documentation](https://docs.docker.com/engine/daemon/proxy/).

For **HAOS** needing system-wide access to GitHub/GHCR at boot, use an upstream router/gateway or external proxy configured at network level, *independent of this HAOS app*. This avoids the circular boot dependency (Supervisor must start the app before the app can help Supervisor pull an image). Network-level routing can be scoped to the HAOS host and preserve the LAN subnets. Keep a recovery route and test IPv4/IPv6 as applicable.

A host-wide transparent proxy inside this add-on would require elevated `NET_ADMIN`, host network access, and persistent host routing/iptables changes, and it cannot offer reliable pre-boot recovery. This project deliberately does not make those changes by default.
