#!/bin/sh
set -eu
umask 077
config_dir=${V2RAYA_CONFIG:-/data/v2raya}
mkdir -p "$config_dir"

if [ ! -x "${V2RAYA_V2RAY_BIN:-/usr/bin/v2raya_core}" ]; then
  echo "v2rayA core executable not found" >&2
  exit 1
fi

# The 2.5.x runtime may have migrated an existing SQLite database schema.
# Preserve a consistent snapshot before downgrading; never delete user data.
if [ -s "$config_dir/v2raya.db" ] && [ ! -e "$config_dir/v2raya-pre-2.4.0.db" ]; then
  sqlite3 "$config_dir/v2raya.db" ".backup '$config_dir/v2raya-pre-2.4.0.db'" \
    || { echo 'Database backup failed; refusing to start to protect settings' >&2; exit 1; }
  echo "Saved pre-2.4.0 database snapshot in $config_dir"
fi

echo 'Starting v2rayA 2.4.0 with AllowInsecure support; UI 2017, SOCKS5 20170, HTTP 20171/20172.'
echo 'Enable LAN Sharing to permit LAN clients. Transparent proxying of HAOS is not supported.'
exec /usr/bin/v2raya
