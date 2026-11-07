#!/bin/sh
set -eu
umask 077
mkdir -p "${V2RAYA_CONFIG:-/data/v2raya}"
if [ ! -x "${V2RAYA_V2RAY_BIN:-/usr/bin/v2raya_core}" ]; then
  echo "v2rayA core executable not found" >&2
  exit 1
fi
echo "Starting v2rayA on 2017 (UI), 20170 (SOCKS5), 20171/20172 (HTTP)."
echo "Enable LAN Sharing in the v2rayA settings to allow LAN clients."
echo "Transparent proxy mode is intentionally not supported."
exec /usr/bin/v2raya
