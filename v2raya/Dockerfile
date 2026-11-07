# Upstream image bundles v2rayA, v2raya_core and routing rule assets.
FROM mzz2017/v2raya:v2.5.13

ARG BUILD_VERSION=0.1.0
ARG BUILD_ARCH=amd64
RUN apk add --no-cache ca-certificates
COPY run.sh /usr/local/bin/ha-v2raya-start
RUN chmod 0755 /usr/local/bin/ha-v2raya-start
ENV V2RAYA_ADDRESS=0.0.0.0:2017 \
    V2RAYA_CONFIG=/data/v2raya \
    V2RAYA_V2RAY_BIN=/usr/bin/v2raya_core
EXPOSE 2017/tcp 20170/tcp 20171/tcp 20172/tcp
LABEL io.hass.version="${BUILD_VERSION}" \
      io.hass.type="app" \
      io.hass.arch="${BUILD_ARCH}" \
      org.opencontainers.image.title="v2rayA Home Assistant Add-on" \
      org.opencontainers.image.source="https://github.com/fwerkor/ha-v2raya-addon"
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
    CMD wget -q -O /dev/null http://127.0.0.1:2017/ || exit 1
ENTRYPOINT ["/usr/local/bin/ha-v2raya-start"]
