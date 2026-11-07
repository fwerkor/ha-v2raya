#!/bin/sh
# Home Assistant OS / Supervised: local app recovery with registry and source fallback.
# Does not change HAOS firewall, Docker configuration, or global networking.
set -eu

VERSION=0.1.1
INDEX_SHA256=db0e6260267759de382d7222c4b285b2659091d9ae69e6ff5e79836f9241239e
PATH_IN_REPO=v2raya_cn
TARGET_NAME=v2raya_cn
CURL=${CURL:-curl}
APP_DIR=${HA_LOCAL_APPS_DIR:-}
REGISTRY_CHOICE=${HA_V2RAYA_REGISTRY:-auto}

fail() { echo "Error: $*" >&2; exit 1; }
info() { printf '%s\n' "$*"; }

case "$REGISTRY_CHOICE" in
  auto|official|cn) ;;
  *) fail 'HA_V2RAYA_REGISTRY must be auto, official, or cn' ;;
esac
command -v "$CURL" >/dev/null 2>&1 || fail 'curl is required'
command -v sha256sum >/dev/null 2>&1 || fail 'sha256sum is required'

if [ -z "$APP_DIR" ]; then
  for dir in /local_apps /addons; do
    if [ -d "$dir" ] && [ -w "$dir" ]; then APP_DIR=$dir; break; fi
  done
fi
[ -n "$APP_DIR" ] && [ -d "$APP_DIR" ] && [ -w "$APP_DIR" ] || fail 'No writable Home Assistant local apps folder. Mount /local_apps (or legacy /addons), or set HA_LOCAL_APPS_DIR.'
[ ! -e "$APP_DIR/$TARGET_NAME" ] || fail "Already exists: $APP_DIR/$TARGET_NAME. No files were overwritten."

TMP=$(mktemp -d)
APP_STAGE=''
trap 'rm -rf "$TMP"; if [ -n "$APP_STAGE" ]; then rm -rf "$APP_STAGE"; fi' EXIT HUP INT TERM

check_registry() {
  host=$1
  url="https://$host/v2/fwerkor/ha-v2raya/manifests/$VERSION"
  hdr="$TMP/registry-head"
  body="$TMP/registry-body"
  code=$($CURL -sSL --connect-timeout 5 --max-time 15 -D "$hdr" -o "$body" -w '%{http_code}' -H 'Accept: application/vnd.oci.image.index.v1+json' "$url" 2>/dev/null) || return 1
  if [ "$code" = 401 ]; then
    challenge=$(grep -i '^www-authenticate:' "$hdr" | tr -d '\r' | head -n 1 || true)
    realm=$(printf '%s' "$challenge" | sed -n 's/.*realm="\([^"]*\)".*/\1/p')
    service=$(printf '%s' "$challenge" | sed -n 's/.*service="\([^"]*\)".*/\1/p')
    scope=$(printf '%s' "$challenge" | sed -n 's/.*scope="\([^"]*\)".*/\1/p')
    [ -n "$realm" ] && [ -n "$service" ] && [ -n "$scope" ] || return 1
    token_json=$($CURL -fsSL --connect-timeout 5 --max-time 15 "$realm?service=$service&scope=$scope" 2>/dev/null) || return 1
    token=$(printf '%s' "$token_json" | sed -n 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    [ -n "$token" ] || return 1
    code=$($CURL -sSL --connect-timeout 5 --max-time 15 -D "$hdr" -o "$body" -w '%{http_code}' \
      -H 'Accept: application/vnd.oci.image.index.v1+json' -H "Authorization: Bearer $token" "$url" 2>/dev/null) || return 1
  fi
  [ "$code" = 200 ] || return 1
  digest=$(sha256sum "$body" | cut -d ' ' -f 1)
  [ "$digest" = "$INDEX_SHA256" ] || { info "  $host returned an unexpected manifest digest; refusing that source."; return 1; }
  grep -Eq '"architecture"[[:space:]]*:[[:space:]]*"amd64"' "$body" || return 1
  grep -Eq '"architecture"[[:space:]]*:[[:space:]]*"arm64"' "$body" || return 1
  return 0
}

info 'Checking accessible image registries (official first, then CN mirror)...'
SELECTED=''
if [ "$REGISTRY_CHOICE" != cn ] && check_registry ghcr.io; then
  SELECTED=ghcr.io
fi
if [ -z "$SELECTED" ] && [ "$REGISTRY_CHOICE" != official ] && check_registry ghcr.dockerproxy.net; then
  SELECTED=ghcr.dockerproxy.net
fi
[ -n "$SELECTED" ] || fail 'Neither allowed image registry serves the expected v0.1.1 multiarch digest. No installation was attempted.'
info "Selected image registry: $SELECTED (verified SHA256:$INDEX_SHA256)"


# Pin the exact add-on files as well as the OCI image. Public CDN is transport only.
verify_file() {
  filename=$1
  expected=''
  case "$filename" in
    config.yaml) expected=6b69d051d2a28b0973bc406eb01472319bec284b97ec0b12fde92189d131aa7b ;;
    DOCS.md) expected=47354236bdc7b22586b337a0edda1a20df671d93fbf882d4744eae17b96710e0 ;;
    CHANGELOG.md) expected=7a8fff297148589ce236010564a9c7c84d6906a03ed6e37091088dd674bd782e ;;
    icon.png) expected=34d2e206be831112f32381658174724b89f909e7152f59c1d49b0bd73a18c79b ;;
    logo.png) expected=1674324267b8b0d1707f4c94eeca565a8b07c09d30ef18d55a4b8234b84b037c ;;
    *) return 1 ;;
  esac
  actual=$(sha256sum "$TMP/source/$filename" | cut -d ' ' -f 1)
  [ "$actual" = "$expected" ]
}

# All files come from the *same* source; a failed or stale source is rejected.
FILES='config.yaml DOCS.md CHANGELOG.md icon.png logo.png'
fetch_source() {
  base=$1
  mkdir -p "$TMP/source"
  for file in $FILES; do
    $CURL -fsSL --connect-timeout 5 --max-time 18 --retry 1 -o "$TMP/source/$file" "$base/$PATH_IN_REPO/$file" 2>/dev/null || return 1
    [ -s "$TMP/source/$file" ] || return 1
    verify_file "$file" || return 1
  done
  grep -Eq '^version:[[:space:]]*"0\.1\.1"' "$TMP/source/config.yaml" || return 1
  grep -Eq '^slug:[[:space:]]*v2raya_proxy_cn' "$TMP/source/config.yaml" || return 1
  grep -Fx 'image: ghcr.dockerproxy.net/fwerkor/ha-v2raya' "$TMP/source/config.yaml" >/dev/null || return 1
  # Standard PNG signatures: no HTML error pages or stale placeholders.
  for file in icon.png logo.png; do
    sig=$(od -An -tx1 -N8 "$TMP/source/$file" | tr -d ' \n')
    [ "$sig" = 89504e470d0a1a0a ] || return 1
  done
  return 0
}

info 'Trying independent code/CDN mirrors...'
SOURCE=''
for base in \
  'https://cdn.jsdelivr.net/gh/fwerkor/ha-v2raya@main' \
  'https://fastly.jsdelivr.net/gh/fwerkor/ha-v2raya@main' \
  'https://cdn.jsdmirror.cn/gh/fwerkor/ha-v2raya@main' \
  'https://raw.githubusercontent.com/fwerkor/ha-v2raya/main'; do
  rm -f "$TMP/source/"* 2>/dev/null || true
  if fetch_source "$base"; then SOURCE=$base; break; fi
done
[ -n "$SOURCE" ] || fail 'No up-to-date source mirror was reachable; local apps folder is unchanged.'
info "Selected source: $SOURCE"

sed "s#^image: ghcr.dockerproxy.net/fwerkor/ha-v2raya#image: $SELECTED/fwerkor/ha-v2raya#" \
  "$TMP/source/config.yaml" > "$TMP/source/config-selected.yaml"
mv "$TMP/source/config-selected.yaml" "$TMP/source/config.yaml"

# Local store path. The existing GitHub-store variant is untouched.
APP_STAGE=$(mktemp -d "$APP_DIR/.ha-v2raya-cn.XXXXXX")
for file in $FILES; do cp "$TMP/source/$file" "$APP_STAGE/$file"; done
mv "$APP_STAGE" "$APP_DIR/$TARGET_NAME"
APP_STAGE=''
info "Installed app definition in $APP_DIR/$TARGET_NAME"

if command -v ha >/dev/null 2>&1; then
  if ha store reload; then
    info 'App store reloaded. Install "v2rayA Proxy (CN Mirror)" from Local apps.'
  else
    info 'Store refresh failed. Refresh the store manually in Home Assistant; files are already installed.'
  fi
else
  info 'Refresh the app store in Home Assistant, then install "v2rayA Proxy (CN Mirror)" from Local apps.'
fi
info 'Do not install the normal and CN variants simultaneously: their default host ports overlap.'
