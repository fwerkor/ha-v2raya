# Home Assistant v2rayA Add-on

## 安装与使用

为 **Home Assistant OS / Supervised** 提供 v2rayA 代理插件，支持 `amd64` 和 `aarch64`。配置保存在 `/data/v2raya`，不修改 HAOS 主机网络。插件使用预构建的 `ghcr.io/fwerkor/ha-v2raya:0.1.1` 镜像，安装时无需在 HAOS 本机从 Docker Hub 构建。

1. 在 HA **设置 → 加载项 → 加载项商店 → 仓库** 添加 `https://github.com/fwerkor/ha-v2raya`。
2. 安装并启动 **v2rayA Proxy**，打开 Web UI 或访问 `http://<HA_IP>:2017`，设置管理员密码。
3. 导入订阅/节点，选择节点并启动。
4. 在 v2rayA 设置启用 **LAN Sharing（局域网共享）**。
5. 其他设备配置 SOCKS5 `socks5://<HA_IP>:20170`，HTTP `http://<HA_IP>:20171`，按规则分流的 HTTP `http://<HA_IP>:20172`。这些宿主端口均可在 HA 插件「网络」设置修改。

**安全：** 代理端口默认不要求认证，绝不能向公网转发；建议限制为可信 VLAN / 局域网设备。管理界面需要强密码。该插件不提供透明代理/TUN，不会接管 HAOS 的网络流量。

详细说明：[v2raya/DOCS.md](v2raya/DOCS.md)。项目不隶属于 Home Assistant 或 v2rayA 官方。

## English

Install the repository `https://github.com/fwerkor/ha-v2raya` in the Home Assistant Add-on Store, start **v2rayA Proxy**, open `http://<HA_IP>:2017`, configure a server and enable **LAN Sharing**. Use SOCKS5 on 20170, HTTP on 20171, or routed HTTP on 20172. Limit access to a trusted LAN: the proxy ports do not have authentication by default. Supports amd64 and aarch64. Installs a prebuilt image from GHCR instead of building locally from Docker Hub.

App artwork: original v2rayA icon from [v2rayA upstream](https://github.com/v2rayA/v2rayA/blob/main/gui/public/static/v2raya-icon.svg), rasterized for Home Assistant.
