# Home Assistant's amd64/arm64 v2rayA add-on, pinned to the last upstream
# version with a working per-node AllowInsecure setting.
FROM alpine:3.22

ARG TARGETARCH
ARG BUILD_VERSION=0.2.0

RUN apk add --no-cache ca-certificates curl tzdata sqlite

RUN set -eu; \
    case "$TARGETARCH" in \
      amd64) bin_arch=x64; app_sha=0a8498c66ea06a9c3f129bac8971330e4ff0dbd67cd940906cc0f6d3d9b58e26; core_sha=6b31f0c50efc46042b6b6acdfe2c78fd8097a8347c84adbcbfdaa3ea37f537d7 ;; \
      arm64) bin_arch=arm64; app_sha=7ac1fecdf2f74da3b9bcc273d9e6038307cc011eca2f4c3fdd6b769d33d7da13; core_sha=6072bf1b96d85fd208a268eb4f3d37664ef571cc66765a2dd5032c8ab5273d4c ;; \
      *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    for component in v2raya v2raya_core; do \
      if [ "$component" = v2raya ]; then checksum="$app_sha"; else checksum="$core_sha"; fi; \
      name="${component}_linux_${bin_arch}_2.4.0"; \
      curl -fL --retry 3 --connect-timeout 10 --max-time 150 \
        "https://github.com/v2rayA/v2rayA/releases/download/v2.4.0/${name}" -o "/tmp/${name}"; \
      printf '%s  %s\n' "$checksum" "/tmp/${name}" | sha256sum -c -; \
      install -m755 "/tmp/${name}" "/usr/bin/${component}"; \
      rm -f "/tmp/${name}"; \
    done; \
    mkdir -p /usr/share/v2raya; \
    for file in geoip.dat geosite.dat; do \
      curl -fL --retry 3 --connect-timeout 10 --max-time 150 \
        "https://raw.githubusercontent.com/mzz2017/dist-v2ray-rules-dat/master/${file}" \
        -o "/usr/share/v2raya/${file}"; \
      test -s "/usr/share/v2raya/${file}"; \
    done; \
    ln -s /usr/share/v2raya /usr/share/xray; \
    ln -s /usr/share/v2raya /usr/share/v2ray

RUN test "$(/usr/bin/v2raya --version)" = '2.4.0' && \
    /usr/bin/v2raya_core version | grep -F 'V2RAYA_CORE 2.4.0'

COPY run.sh /usr/local/bin/ha-v2raya-start
RUN chmod 0755 /usr/local/bin/ha-v2raya-start

ENV V2RAYA_ADDRESS=0.0.0.0:2017 \
    V2RAYA_CONFIG=/data/v2raya \
    V2RAYA_V2RAY_BIN=/usr/bin/v2raya_core \
    V2RAYA_CORE_TYPE=xray \
    V2RAYA_V2RAY_ASSETSDIR=/usr/share/v2raya

EXPOSE 2017/tcp 20170/tcp 20171/tcp 20172/tcp
LABEL io.hass.version="${BUILD_VERSION}" \
      io.hass.type="app" \
      io.hass.arch="aarch64|amd64" \
      org.opencontainers.image.title="v2rayA 2.4.0 Home Assistant Add-on" \
      org.opencontainers.image.source="https://github.com/fwerkor/ha-v2raya"
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
    CMD wget -q -O /dev/null http://127.0.0.1:2017/ || exit 1
ENTRYPOINT ["/usr/local/bin/ha-v2raya-start"]
