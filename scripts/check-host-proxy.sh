#!/bin/sh
# Read-only connectivity check from Home Assistant Terminal & SSH or another host.
# Usage: sh check-host-proxy.sh <HAOS_IPV4_OR_HOSTNAME> [HTTP_PORT]
set -eu

usage() {
  printf 'Usage: sh %s <HAOS_IP_OR_HOSTNAME> [HTTP_PORT]\n' "$0" >&2
  printf 'Example: sh %s 192.168.1.10 20171\n' "$0" >&2
  exit 2
}

[ "$#" -ge 1 ] && [ "$#" -le 2 ] || usage
HOST=$1
PORT=${2:-20171}
case "$HOST" in
  *[!A-Za-z0-9._-]*|'') usage ;;
esac
case "$PORT" in
  *[!0-9]*|'') usage ;;
esac
[ "$PORT" -gt 0 ] && [ "$PORT" -le 65535 ] || usage
command -v curl >/dev/null 2>&1 || { echo 'curl is required' >&2; exit 2; }
PROXY="http://$HOST:$PORT"

printf 'Checking v2rayA explicit HTTP proxy at %s\n' "$PROXY"
printf 'These tests do not change HAOS routes, Supervisor, Docker, or environment variables.\n'

check() {
  label=$1
  url=$2
  expected=$3
  result=$(curl --noproxy '' --proxy "$PROXY" --connect-timeout 5 --max-time 18 \
    --silent --show-error --output /dev/null --write-out '%{http_code}' "$url") || {
    printf 'FAIL %-21s Could not connect through proxy to %s\n' "$label" "$url"
    return 1
  }
  case " $expected " in
    *" $result "*) printf 'PASS %-21s HTTP %s\n' "$label" "$result" ;;
    *) printf 'FAIL %-21s Unexpected HTTP %s (expected: %s)\n' "$label" "$result" "$expected"; return 1 ;;
  esac
}

failed=0
check GitHub https://github.com/ '200 301 302' || failed=1
check GHCR https://ghcr.io/v2/ '200 401' || failed=1
check Docker-Hub https://registry-1.docker.io/v2/ '200 401' || failed=1

if [ "$failed" -ne 0 ]; then
  printf 'Check the add-on status, active proxy server, LAN Sharing, and mapped port.\n' >&2
  exit 1
fi
printf '\nExplicit HTTP proxy is reachable. This does NOT mean Supervisor/Docker are configured to use it.\n'
printf 'Applications supporting HTTPS_PROXY can use HTTPS_PROXY=%s (plus suitable NO_PROXY).\n' "$PROXY"
