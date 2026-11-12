#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'python3 -c "import shutil,sys; shutil.rmtree(sys.argv[1],ignore_errors=True)" "$TMP"' EXIT

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
  output="$TMP/$distro"
  mkdir -p "$output"
  chmod 0777 "$output"
  echo "==> Clean v2 browser route: $distro ($image)"
  docker run --rm \
    --shm-size=1g \
    --volume "$ROOT/lib/ternux-install-firefox-esr.sh:/ternux-install-firefox-esr.sh:ro" \
    --volume "$ROOT/tests/firefox_xvfb_probe.sh:/firefox_xvfb_probe.sh:ro" \
    --volume "$output:/out" \
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
      su -s /bin/sh browser -c "/firefox_xvfb_probe.sh \"$browser\""
      test -s /out/firefox.png
    '
  python3 - "$output/firefox.png" "$distro" <<'PY'
import pathlib
import struct
import sys

path = pathlib.Path(sys.argv[1])
data = path.read_bytes()
assert data[:8] == b"\x89PNG\r\n\x1a\n", f"{sys.argv[2]}: Firefox output is not PNG"
width, height = struct.unpack(">II", data[16:24])
assert width >= 640 and height >= 400, f"{sys.argv[2]}: implausible browser frame {width}x{height}"
print(f"PASS: {sys.argv[2]} clean browser painted {width}x{height} frame")
PY
done
