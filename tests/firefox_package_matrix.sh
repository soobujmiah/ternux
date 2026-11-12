#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
command -v docker >/dev/null 2>&1 || {
  echo 'Docker is required for the clean v2 Firefox package matrix.' >&2
  exit 2
}

# v2's supported clean desktop profiles are deliberately limited to these
# three. Other named recipes remain available but are not v2-qualified.
profiles=(
  'debian|debian:trixie'
  'ubuntu|ubuntu:24.04'
  'alpine|alpine:3.24'
)

for profile in "${profiles[@]}"; do
  distro="${profile%%|*}"
  image="${profile#*|}"
  echo "==> Clean v2 browser route: $distro ($image)"
  docker run --rm \
    --shm-size=1g \
    --volume "$ROOT/lib/ternux-install-firefox-esr.sh:/ternux-install-firefox-esr.sh:ro" \
    --volume "$ROOT/tests/firefox_xvfb_probe.sh:/firefox_xvfb_probe.sh:ro" \
    --env "TNX_BROWSER_PROFILE=$distro" \
    "$image" sh -ec '
      case "$TNX_BROWSER_PROFILE" in
        debian)
          apt-get update
          DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            dbus dbus-x11 desktop-file-utils firefox-esr openbox passwd xdotool xvfb
          ;;
        ubuntu)
          apt-get update
          DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            ca-certificates curl dbus dbus-x11 desktop-file-utils libasound2t64 \
            libdbus-glib-1-2 libgbm1 libgtk-3-0t64 libnss3 libpango-1.0-0 \
            libx11-xcb1 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
            libxrender1 libxss1 libxt6 libxtst6 openbox passwd xdotool xz-utils xvfb
          bash /ternux-install-firefox-esr.sh
          ;;
        alpine)
          apk add --no-cache dbus dbus-x11 desktop-file-utils firefox-esr openbox shadow xdotool xvfb
          ;;
        *) echo "Unexpected v2 browser profile: $TNX_BROWSER_PROFILE" >&2; exit 2 ;;
      esac
      if [ "$TNX_BROWSER_PROFILE" = alpine ]; then
        adduser -D browser
      else
        useradd -m browser
      fi
      install -d -o browser -g browser /tmp/firefox-home /tmp/firefox-run
      chmod 0700 /tmp/firefox-run
      browser="$(command -v firefox-esr || command -v firefox || true)"
      [ -n "$browser" ] && [ -x "$browser" ] || {
        echo "Firefox executable missing for $TNX_BROWSER_PROFILE" >&2
        exit 1
      }
      desktop-file-validate /usr/local/share/applications/firefox-esr.desktop 2>/dev/null ||
        desktop-file-validate /usr/share/applications/firefox-esr.desktop 2>/dev/null ||
        desktop-file-validate /usr/share/applications/firefox.desktop
      su -s /bin/sh browser -c "sh /firefox_xvfb_probe.sh \"$browser\""
    '
done
