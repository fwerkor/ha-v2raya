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

## 中国大陆网络备用安装 / CN fallback

如果 HAOS 日志显示 GitHub `git ls-remote` TLS/EOF 错误，Supervisor 无法更新其仓库缓存，仍可能使用旧版 Dockerfile 并访问 Docker Hub。此时刷新仓库并不能解决所有网络问题。原版仍以官方 GHCR 为首选，另提供 **v2rayA Proxy (CN Mirror)**，通过 `ghcr.dockerproxy.net` 拉取相同的预构建镜像。镜像站为第三方服务，使用时需自行评估其可用性和信任风险。

**如果 GitHub 仓库不可访问**，在 Home Assistant **Terminal & SSH** 中执行（需要支持 `/local_apps` 或 `/addons` 的终端；脚本不会修改系统 Docker/网络配置）：

```sh
curl -fL --retry 2 --connect-timeout 5 -o /tmp/ha-v2raya-install.sh \
  https://cdn.jsdelivr.net/gh/fwerkor/ha-v2raya@main/scripts/install-local-cn.sh
sh /tmp/ha-v2raya-install.sh
```

脚本自动检查官方 GHCR 和 CN 镜像站，校验 **v0.1.1 OCI index SHA-256** 以及 amd64/arm64 架构；然后从 jsDelivr、Fastly、JSDMirror、GitHub Raw 依次获取加载项文件，生成本地加载项。任何来源都失败时中止，不会继续使用错误的镜像。安装后在商店的本地应用（Local apps）中选择 **v2rayA Proxy (CN Mirror)**。如果要强制选国内镜像站，运行 `HA_V2RAYA_REGISTRY=cn sh /tmp/ha-v2raya-install.sh`。

这个切换发生在安装脚本执行阶段；**Home Assistant Supervisor 本身不会在镜像拉取失败后自动换站**。不要同时安装两个变体（端口冲突）。v0.1.1 校验值是固定的，以后升级版本须更新脚本的校验值。

## HAOS 本机使用代理

HAOS 上能显式使用 v2rayA HTTP/SOCKS5 代理，但 **Supervisor 与 Docker 镜像下载不会自动走代理**。HAOS 的只读系统不支持通过本加载项持久设置 Docker daemon 代理；也不能在加载项尚未启动时解决 Supervisor 下载问题。

已提供只读连接诊断脚本 `scripts/check-host-proxy.sh`，以及详细说明：[HAOS host proxy guide](docs-host-proxy.md)。如确需整机下载可靠地走代理，建议在独立的路由器/网关侧实现，使 HAOS 在插件启动前也能连接外网，并确保局域网网段直连。
